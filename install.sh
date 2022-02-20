#!/bin/bash

if [ $(id -u) -ne 0 ]; then
	sudo "$0"
	exit
fi

set -e
function abort { echo "$1" >&2; exit -1 }

cd "$(dirname "$0")"
BASE="$(pwd)"

CREDENTIALS="$BASE/credentials.ini"

[ -f "$CREDENTIALS" ] || abort "Credentials file not found: $CREDENTIALS"

DEFAULT_CONFIG="$BASE/config.sh"
DEFAULT_HOSTNAME="$(hostname)"
DEFAULT_KEY_TYPE="ecdsa"
DEFAULT_KEY_SIZE="2048"
DEFAULT_CURVE="secp384r1"
DEFAULT_DEPLOY_HOOK="$BASE/deploy.sh"

CONFIG="${1:-$DEFAULT_CONFIG}"

[ -f "$CONFIG" ] || abort "Could not find configuration file: $CONFIG"

source "$CONFIG"

REQUIRED_FIELDS=( "DOMAIN" "EMAIL" )
for key in "${REQUIRED_FIELDS[@]}"; do
	[ ! -z "$key" ] || abort "Required value not set in configuration: $key"
done

HOSTNAME="${HOSTNAME:-$DEFAULT_HOSTNAME}"
KEY_TYPE="${KEY_TYPE:-$DEFAULT_KEY_TYPE}"
KEY_SIZE="${KEY_SIZE:-$DEFAULT_KEY_SIZE}"
KEY_CURVE="${KEY_CURVE:-$DEFAULT_KEY_CURVE}"
DEPLOY_HOOK="${DEPLOY_HOOK:-$DEFAULT_DEPLOY_HOOK}"

[ -x "$DEPLOY_HOOK" ] || abort "Deploy hook missing or not executable: $DEPLOY_HOOK"

echo "Ensuring dependencies..."
if [ -x "/usr/bin/apt" ]; then
	/usr/bin/apt update && \
	/usr/bin/apt -y install certbot python3-certbot-dns-cloudflare
elif [ -x "/usr/bin/pacman" ]; then
	/usr/bin/pacman --noconfirm --needed -Sy certbot certbot-dns-cloudflare
else
	abort "Could not find package manager, aborting!"
fi

FULLDOMAIN="$HOSTNAME.$DOMAIN"
CERTROOT="/etc/letsencrypt/live/$FULLDOMAIN"

CERTBOT_ARGUMENTS=(
	--email "$EMAIL"
	--domain "$FULLDOMAIN"
	--cert-name "$FULLDOMAIN"
	--key-type "$KEY_TYPE"
	--rsa-key-size "$KEY_SIZE"
	--elliptic-curve "$KEY_CURVE"
	--deploy-hook "$DEPLOY_HOOK $CERTROOT"
	--dns-cloudflare-credentials "$CREDENTIALS"
)

echo "Using the following provided arguments: $CERTBOT_ARGUMENTS"
read -p "Please verify, type Y and press Enter to proceed with the above values: " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    abort "User aborted the operation."
fi

/usr/bin/certbot certonly --agree-tos --no-eff-email --dns-cloudflare $CERTBOT_ARGUMENTS
