#!/usr/bin/env sh

# Script to generate SSL certificates for Kafka broker to use TLS
# Author: Ashish Ranjan
# License: AGPL-3.0-or-later

# ======================================================================

# Description:
# https://kafka.apache.org/22/documentation.html#security_ssl

# Usage:
# > Go to the root of the repo
# > Run ./bin/create_kafka_tls_certificates.sh

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
SECRETS_DIR="common-kafka/secrets"
KEYSTORE_PASSWORD=$(cat "$SECRETS_DIR/server.keystore.password")

# How to create certificates with multiple Subject Alternative Names:
# https://www.golinuxcloud.com/openssl-subject-alternative-name/

# Create an openssl config file
cat >"$TMP_DIR/openssl_kafka.cnf" <<EOF
[req]
req_extensions = req_ext

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = common-kafka
EOF

if [ -e "$SECRETS_DIR/server.keystore.jks" ]; then
  printf "> Removing previous certificate before generating a new one\n\n"
  rm "$SECRETS_DIR/server.keystore.jks"
fi

printf "> Generating SSL certificate and key for our kafka broker:\n\n"
keytool -genkey \
  -keystore "$SECRETS_DIR/server.keystore.jks" \
  -alias common-kafka \
  -storepass "$KEYSTORE_PASSWORD" \
  -validity 365 \
  -keyalg RSA \
  -dname "CN=localhost, OU=Engineering, O=YetAnotherIT, L=Bangalore, S=Karnataka, C=IN"

printf "> Exporting CSR (certificate signing request) from keystore:\n\n"
keytool -certreq -file "$TMP_DIR/cert-csr" \
  -keystore "$SECRETS_DIR/server.keystore.jks" \
  -alias common-kafka \
  -storepass "$KEYSTORE_PASSWORD"

printf "> Signing CSR with the mkcert's CA:\n\n"
openssl x509 -req \
  -CAcreateserial \
  -CA "$MKCERT_CACERT_PATH" \
  -CAkey "$MKCERT_CAKEY_PATH" \
  -in "$TMP_DIR/cert-csr" \
  -out "$TMP_DIR/cert-signed" \
  -days 365 \
  -sha256 \
  -extensions req_ext -extfile "$TMP_DIR/openssl_kafka.cnf"

printf "> Importing mkcert's CA certificate into the keystore:\n\n"
keytool -import -file "$MKCERT_CACERT_PATH" \
  -keystore "$SECRETS_DIR/server.keystore.jks" \
  -alias caroot \
  -storepass "$KEYSTORE_PASSWORD"

printf "> Importing signed certificate into the keystore:\n\n"
keytool -import -file "$TMP_DIR/cert-signed" \
  -keystore "$SECRETS_DIR/server.keystore.jks" \
  -alias common-kafka \
  -storepass "$KEYSTORE_PASSWORD"

printf "\n\n\n\n\n\n"
printf "> Please verify the contents of generated certificates:\n\n"
keytool -list -v -keystore "$SECRETS_DIR/server.keystore.jks" -storepass "$KEYSTORE_PASSWORD"
