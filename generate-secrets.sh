#!/bin/bash
if [[ ! $(dirname "${BASH_SOURCE}") == "." ]]; then
  echo Please run this script from wihtin the gxf-platform folder
  exit 1
fi

function generate_passphrase {
  echo "$(tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1)"
}

# Constants
CA_CERT=ca.crt
CA_KEY=ca.key
CA_PASS=$(generate_passphrase)

function generate_httpd_certs {

  echo "Generating httpd certs"
  key_passphrase=$(generate_passphrase)

  filename=./httpd-certs

  echo "Creating csr and key file for httpd"
  openssl req -new -newkey rsa:4096 -passout pass:"${key_passphrase}" \
  -keyout "${filename}.key" -out "${filename}.csr" \
  -subj "/C=NL/ST=Gelderland/L=Arnhem/O=Alliander/OU=IT/CN=httpd"

  echo "Creating pem file for httpd"
  openssl x509 -req -CA ${CA_CERT} -CAkey ${CA_KEY} -in ${filename}.csr \
  -out ${filename}.pem -days 730 -CAcreateserial -passin pass:"${CA_PASS}"

  cat > ${filename}.generated.sh << EOF
#!/bin/sh
echo ${key_passphrase}
EOF

  secret_name=apache-httpd-certs

  kubectl create secret generic ${secret_name}\
  --from-file=root.crt="${CA_CERT}" \
  --from-file=server.crt="${filename}.pem" \
  --from-file=server.key="${filename}.key" \
  --from-file=server-key-password="${filename}.generated.sh"

}

function generate_jms_keystore {

  keystore_type=$1
  app=$2
  CN=$3

  keystore_passphrase=$(generate_passphrase)
  truststore_passphrase=$(generate_passphrase)

  filename="${CN}-${app}-${keystore_type}"

  echo "Creating csr and key file for jms"
  
  openssl req -new -newkey rsa:2048 -nodes \
  -keyout "${filename}.key" -out "${filename}.csr" \
  -subj "/C=NL/ST=Gelderland/L=Arnhem/O=LFEnergy/OU=IT/CN=${CN}"
  
  echo "Creating pem file for jms"
  
  openssl x509 -req -CA ${CA_CERT} -CAkey ${CA_KEY} -in "${filename}".csr \
  -out "${filename}".pem -days 730 -CAcreateserial -passin pass:"${CA_PASS}" > /dev/null

  echo "Creating p12 keystore for jms"

  openssl pkcs12 -export -inkey "${filename}".key -in "${filename}".pem \
  -passout pass:"$keystore_passphrase" -out "${filename}".keystore.p12

  echo "Importing jms p12 keystore into JKS keystore"

  keytool -importkeystore -srckeystore "${filename}".keystore.p12 -srcstoretype PKCS12 \
  -destkeystore "${filename}".keystore.jks -deststoretype JKS \
  -srcstorepass "${keystore_passphrase}" -deststorepass "${keystore_passphrase}" \
  -noprompt

  echo "Creating p12 truststore for jms"
  
  openssl pkcs12 -export -nokeys -in ${CA_CERT} -passout pass:"$truststore_passphrase" -out "${filename}".truststore.p12

  echo "Importing jms p12 truststore into JKS truststore"

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

  kubectl create secret generic "${secret_name}" \
      --from-file=${keystore_name}="${filename}".keystore.jks \
      --from-file=${truststore_name}="${filename}".truststore.jks \
      --from-literal=keyStorePassword="${keystore_passphrase}" \
      --from-literal=trustStorePassword="${truststore_passphrase}"

}

function generate_ws_client_certs {

    keystore_passphrase=$(generate_passphrase)
    truststore_passphrase=$(generate_passphrase)

    clients_file="test-organisations"
    echo "Getting organisations from $clients_file"

    for client in $(cat $clients_file) ;
    do
        echo "Generating files for ${client}"
        filename="${client}"

        # create certificate signing request
        openssl req -new -newkey rsa:4096 -passout pass:"${keystore_passphrase}" \
            -keyout "${filename}.key" -out "${filename}.csr" \
            -subj /commonName="${client}"

        # sign certificate
        openssl x509 -req -CA ${CA_CERT} -CAkey ${CA_KEY} \
            -in ${filename}.csr \
            -out ${filename}.pem \
            -days 730 -CAcreateserial \
            -passin pass:${CA_PASS}

        # generate pfx
        pfx_file="${client}.pfx"
        openssl pkcs12 -export \
            -inkey "${filename}.key" \
            -in "${filename}.pem" \
            -certfile ${CA_CERT} \
            -out "${pfx_file}" \
            -passin pass:"${keystore_passphrase}" \
            -passout pass:"${keystore_passphrase}"

        # generate sealed secret
        client_helmproof="$(echo "${client//_/-}" | tr '[:upper:]' '[:lower:]')"
        secret_name="${client_helmproof}-cert"

        kubectl create secret generic ${secret_name} \
            --from-file=${pfx_file}
    done

    keytool -import -keystore organisations-truststore.jks -file ${CA_CERT} \
        -storepass "${truststore_passphrase}" -noprompt

    secret_name=organisations-ws-client-certs

    kubectl create secret generic ${secret_name} \
        --from-file=trust.jks="organisations-truststore.jks" \
        --from-literal=keystore-password="${keystore_passphrase}" \
        --from-literal=truststore-password="${truststore_passphrase}"
}

function generate_ca_cert {
  echo "Generating root key"
  openssl genpkey -aes-256-cbc -pass pass:"${CA_PASS}" -algorithm RSA -out "${CA_KEY}" -pkeyopt rsa_keygen_bits:4096
  echo "Generating root cert"
  openssl req -x509 -new -nodes -key ${CA_KEY} -passin pass:"${CA_PASS}" -sha256 -days 365 -out ${CA_CERT} -subj "/C=NL/ST=Gelderland/L=Arnhem/O=LFEnergy/OU=IT/CN=Generated Root CA"

}

function clean_up_files {
  echo "Cleaning up all created files"
  find . -type f \( -name \*.csr -o -name \*.key -o -name \*.p12 -o -name \*.jks -o -name \*.pem -o -name \*.pfx -o -name \*.cer -o -name \*.crt -o -name \*.srl -o -name \*.der -o -name \*.generated.sh \) | xargs rm
}

function generate_oslp_signing_keys {
  PRIVATE_FILE=oslp_test_ecdsa_private
  PUBLIC_FILE=oslp_test_ecdsa_public

  echo "Generate keys ${PRIVATE_FILE}.pem/.der and ${PUBLIC_FILE}.pem/.der"
  openssl ecparam -genkey -name prime256v1 -out ${PRIVATE_FILE}.pem
  openssl ec -in ${PRIVATE_FILE}.pem -out ${PUBLIC_FILE}.pem -pubout

  openssl pkcs8 -topk8 -in ${PRIVATE_FILE}.pem -out ${PRIVATE_FILE}.der -outform der -nocrypt
  openssl ec -in ${PUBLIC_FILE}.pem -out ${PUBLIC_FILE}.der -outform der -pubin -pubout

  echo "Generating secrets for oslp"

  secret_name="oslp-signing-keys"

  kubectl create secret generic "${secret_name}" \
      --from-file=oslp_test_ecdsa_private.der="oslp_test_ecdsa_private.der" \
      --from-file=oslp_test_ecdsa_public.der="oslp_test_ecdsa_public.der"
}

echo "Generating app secrets"
clean_up_files
kubectl delete --all secrets
generate_ca_cert
generate_jms_keystore "client" "gxf-platform" "activemq"
generate_jms_keystore "server" "gxf-platform" "activemq"
generate_oslp_signing_keys
generate_httpd_certs
generate_ws_client_certs
clean_up_files
echo "App secrets created"
