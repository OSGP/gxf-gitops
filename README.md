# GXF gitops
Gitops repo for GXF platform and cucumber tests. This repo can also be used to run the platform and/or cucumber tests 
locally. It is using K3D to start up a kubernetes cluster. 

# Requirements to run the GXF platform locally
- Unix file system: Linux, Mac or WSL
- Enough ram: at least 32GB
- Installed software:
  - Docker
  - Helm
  - Kubectl

# How to set up the GXF platform or cucumber tests locally
- Run the `setup.sh` script, this will download, install and then use `k3d` to create a local  cluster named `test`. 
  - When you add an argument to this setup script it will create a local K3D image-registry and will install the dev chart.
    This dev chart will install a kubernetes dashboard and PgWeb instance on the just created kubernetes cluster
  - This `setup.sh` script will also create the necessary secrets needed to deploy the GXF containers
- After the `setup.sh` script you can use the `port-forward.sh` script in the dev chart to get access to you kubernetes dashboard
- Now you can install the GXF platform by running the `template-apply.sh` script in the gxf-platform chart. 
  This will install the complete GXF platform to the just created kubernetes dashboard
- Now you can run the `template-apply.sh` in the gxf-cucumber chart. However, you need to supply a correct values file. 
  You can supply this values file by adding `--valuesFile <values file in ci folder>`
  - To see extra logs of the cucumber tests you can have a look at `/tmp/k3dvolume`, there should be some logs present. 
