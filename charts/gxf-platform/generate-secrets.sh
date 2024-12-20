# bin/bash
if [[ ! $(dirname "${BASH_SOURCE}") == "." ]]; then
  echo Please run this script from wihtin the gxf-platform folder
  exit 1
fi

function generate_passphrase {
    echo $(tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1)
}

# Constants
CA_CERT=ca.crt
CA_KEY=ca.key
CA_PASS=$(generate_passphrase)

function generate_jms_keystore {

  keystore_type=$1
  app=$2
  CN=$3

  keystore_passphrase=$(generate_passphrase)
  truststore_passphrase=$(generate_passphrase)

  filename="${CN}-${app}-${keystore_type}"

  echo "Creating csr en key file"
  
  openssl req -new -newkey rsa:2048 -nodes \
  -keyout "${filename}.key" -out "${filename}.csr" \
  -subj "/C=NL/ST=Gelderland/L=Arnhem/O=LFEnergy/OU=IT/CN=${CN}"
  
  echo "Creating pem file"
  
  openssl x509 -req -CA ${CA_CERT} -CAkey ${CA_KEY} -in "${filename}".csr \
  -out "${filename}".pem -days 730 -CAcreateserial -passin pass:"${CA_PASS}" > /dev/null

  echo "Creating p12 keystore"

  openssl pkcs12 -export -inkey "${filename}".key -in "${filename}".pem \
  -passout pass:"$keystore_passphrase" -out "${filename}".keystore.p12

  echo "Importing p12 keystore into JKS keystore"

  keytool -importkeystore -srckeystore "${filename}".keystore.p12 -srcstoretype PKCS12 \
  -destkeystore "${filename}".keystore.jks -deststoretype JKS \
  -srcstorepass "${keystore_passphrase}" -deststorepass "${keystore_passphrase}" \
  -noprompt

  echo "Creating p12 truststore"
  
  openssl pkcs12 -export -nokeys -in ${CA_CERT} -passout pass:"$truststore_passphrase" -out "${filename}".truststore.p12

  echo "Importing p12 truststore into JKS truststore"

  keytool -import -alias truststore -keystore "${filename}".truststore.jks -file ${CA_CERT} -storepass "${truststore_passphrase}" -noprompt

  if [ "$keystore_type" = "client" ]
  then
      keystore_name=client.ks
      truststore_name=broker.ts
  elif [ "$keystore_type" = "server" ]
  then
      keystore_name=broker.ks
      truststore_name=client.ts
  else
      echo "Error: Unknown keystore type (client or server)"
      exit 1
  fi

  secret_name="${CN,,}-jms-${keystore_type,,}-certs"
  secret_directory="templates/activemq"
  mkdir -p "${secret_directory}"

  secret_file="${secret_directory}/${secret_name}.yaml"
  echo "# yamllint disable rule:line-length" > "${secret_file}"


  kubectl create secret generic "${secret_name}" \
      --from-file=${keystore_name}="${filename}".keystore.jks \
      --from-file=${truststore_name}="${filename}".truststore.jks \
      --from-literal=keyStorePassword="${keystore_passphrase}" \
      --from-literal=trustStorePassword="${truststore_passphrase}" \
      --dry-run=client -o yaml >> "${secret_file}"

}

function generate_ca_cert {
  echo "Generating root key"
  openssl genpkey -aes-256-cbc -pass pass:"${CA_PASS}" -algorithm RSA -out "${CA_KEY}" -pkeyopt rsa_keygen_bits:4096
  echo "Generating root cert"
  openssl req -x509 -new -nodes -key ${CA_KEY} -passin pass:"${CA_PASS}" -sha256 -days 365 -out ${CA_CERT} -subj "/C=NL/ST=Gelderland/L=Arnhem/O=LFEnergy/OU=IT/CN=Generated Root CA"

}

function clean_up_files {
  echo "Cleaning up all created files"
  find .. -type f \( -name \*.csr -o -name \*.key -o -name \*.p12 -o -name \*.jks -o -name \*.pem -o -name \*.pfx -o -name \*.cer -o -name \*.crt -o -name \*.srl \) | xargs rm
}

clean_up_files
generate_ca_cert
generate_jms_keystore "client" "gxf-platform" "activemq"
generate_jms_keystore "server" "gxf-platform" "activemq"
clean_up_files
