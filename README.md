# acme-cloudflare

This repository contains a script used to bootstrap `certbot` configurations for provisioning my local servers with LetsEncrypt certificates using the DNS-01 challenge with the Cloudflare provider plugin.

Currently, the following operating systems are supported, support for more will be added as the need arises:
* Debian 10/11
* Arch Linux

## Configuration

To configure and use this script, first rename the included example files as follows:
* `config.example` => `config.sh`
* `deploy.example` => `deploy.sh`
* `credentials.example` => `credentials.ini`

### config.sh

Modify this file as you see fit to set the desired contact info, domain, hostname, key type and deployment script. Only the `EMAIL` and `DOMAIN` fields are required. The defaults are the following:
* `KEY_TYPE`: `ecdsa`
* `KEY_SIZE`: `2048` (ignored)
* `KEY_CURVE`: `secp384r1`
* `HOSTNAME`: Determined automatically
* `DEPLOY_HOOK`: File named `deploy.sh` located in the same directory as `install.sh`

### deploy.sh

This script is called with the certificate root directory as the first argument when certificates are issued and renewed. Under this path, you will find the following files: 
* `cert.pem`: The server certificate
* `privkey.pem`: The server private key
* `ca.pem`: The certificate of the CA that signed the certificate
* `fullchain.pem`: The full certificate chain containing both server and CA certificates

Modify this script to handle any deployment steps after all certificate issuances and renewals. Typical operations would include permission adjustments, symlink creations and restarting services using the concerned certificates.

An alternative deployment script can be specified via the `DEPLOY_HOOK` field in `config.sh`. You will probably want to do this when using different configuration files in a multi-environment scenario.

### credentials.ini

In this file, set your Cloudflare API token after `dns_cloudflare_api_token = `. Make sure that the given API token has the necessary permissions to edit the zone of the domain set in your configuration file. At this time, no alternate credentials file can be specified.

## Running the script

Execute the installation script by running `./install.sh`. An alternative configuration file can be specified as a commandline argument. This is especially useful when managing multiple environments from the same host, as it gives you the flexibility to use a different configuration for each environment. If no argument is specified, the script will attempt to load `config.sh` located in the same directory as the script itself.

The script will take care of acquiring any dependencies using your system's built-in package manager. After verifying your configuration and ensuring the presence of all dependencies, it will ask you to confirm the parameters that will be used to request your certificates. Upon confirmation, it will run `certbot` with the given values.

After successfully requesting the certificates, it will run the deployment script set in the configuration file as `DEPLOY_HOOK`. If this is not set, it will run `deploy.sh` located in the same directory as `install.sh`. This script will also be run when certificates are renewed. Make sure that this script remains executable and at the same location. If the script is ever moved, you will need to run `install.sh` again for `certbot`'s configuration to be updated.
