#!/usr/bin/env sh

# Script to generate SSL certificates for Valkey to use TLS
# Author: Ashish Ranjan
# License: AGPL-3.0-or-later

# ======================================================================

# Usage:
# > Go to the root of the repo
# > Run ./bin/create_valkey_tls_certificates.sh

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

if [ -z "$MKCERT_CAKEY_PATH" ]; then
  echo "Please provide mkcert's root CA key path in environment variable \$MKCERT_CAKEY_PATH"
  exit
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

TMP_DIR=$(mktemp -d)
SECRETS_DIR="configs/valkey/secrets"

mkdir -p $SECRETS_DIR

# How to create certificates with multiple Subject Alternative Names:
# https://www.golinuxcloud.com/openssl-subject-alternative-name/

# Create an openssl config file
cat >"$TMP_DIR/openssl_valkey.cnf" <<EOF
[req]
req_extensions = req_ext

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = valkey
DNS.3 = redis
EOF

printf "> Generating TLS private key for Valkey:\n\n"
openssl genpkey -algorithm ED25519 -out "$SECRETS_DIR/valkey.key"

printf "> Generating CSR (certificate signing request) for Valkey:\n\n"
openssl req \
  -new \
  -key "$SECRETS_DIR/valkey.key" \
  -out "$TMP_DIR/valkey.csr" \
  -subj "/CN=localhost/OU=Engineering/O=YetAnotherIT/L=Bangalore/ST=Karnataka/C=IN"

printf "> Signing CSR with the mkcert's CA:\n\n"
openssl x509 -req \
  -CAcreateserial \
  -CA "$MKCERT_CACERT_PATH" \
  -CAkey "$MKCERT_CAKEY_PATH" \
  -in "$TMP_DIR/valkey.csr" \
  -out "$SECRETS_DIR/valkey.cert" \
  -days 365 \
  -sha256 \
  -extensions req_ext -extfile "$TMP_DIR/openssl_valkey.cnf"

printf "\n\n\n\n\n\n"
printf "> Please verify the contents of generated certificates for Valkey:\n\n"
openssl x509 -text -noout -in "$SECRETS_DIR/valkey.cert"
