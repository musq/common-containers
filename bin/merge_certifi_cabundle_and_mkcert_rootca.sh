#!/usr/bin/env sh

# Script to merge certifi's CA bundle with mkcert's rootCA file
# Author: Ashish Ranjan
# License: AGPL-3.0-or-later

# ======================================================================

# Description:
# The merged CA bundle witll be passed to REQUESTS_CA_BUNDLE environment
# variable to be used by python-requests package to validate self-signed
# certificates (from mkcert) for local development.

# Usage:
# > Go to the root of the repo
# > Run ./bin/merge_certifi_cabundle_and_mkcert_rootca.sh

# ======================================================================

# Unofficial POSIX Shell Strict Mode
# https://gist.github.com/EvgenyOrekhov/5c1418f4710558b5d6717d9e69c6e929
set -o errexit
set -o nounset
IFS=$(printf '\n\t')

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# shellcheck disable=SC1091
. .env # Source necessary environment variables from .env file.

if [ -z "$MKCERT_CACERT_PATH" ]; then
  echo "Please provide mkcert's root CA file path in environment variable \$MKCERT_CACERT_PATH"
  exit
fi

if [ -z "$CERTIFI_PLUS_MKCERT_CACERT_PATH" ]; then
  echo "Please set the environment variable \$CERITFI_PLUS_MKCERT_CACERT_PATH to the file path where the merged CA file will be stored."
  exit
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

TMP_DIR=$(mktemp -d)

curl --silent --show-error --location --output \
  "$TMP_DIR/certifi_cacert.pem" \
  https://raw.githubusercontent.com/certifi/python-certifi/master/certifi/cacert.pem

echo "
# Issuer: CN=mkcert O=mkcert development CA OU=Local Machine
# Subject: CN=mkcert O=mkcert development CA OU=Local Machine
# Label: "mkcert development CA"
# Serial: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# MD5 Fingerprint: xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
# SHA1 Fingerprint: xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
# SHA256 Fingerprint: xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx" \
  >"$TMP_DIR/mkcert_cacert_header.pem"

cat "$TMP_DIR/certifi_cacert.pem" \
  "$TMP_DIR/mkcert_cacert_header.pem" \
  "$MKCERT_CACERT_PATH" \
  >"$CERTIFI_PLUS_MKCERT_CACERT_PATH"

echo "Merged CA cert location: $CERTIFI_PLUS_MKCERT_CACERT_PATH"
