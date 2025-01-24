# ComCon - Common Containers

A set of containers that are usually needed during software development.

## Clone

```sh
# Create ~/src directory and enter it
# This is important because the container volumes are going to reside in ~/src/comcon-volumes/
mkdir -p ~/src && cd ~/src

# Clone comcon
git clone --recurse-submodules git@github.com:musq/comcon.git

# Go inside
cd comcon

# Update all related repos
git submodule foreach 'git fetch && git rebase origin/main main'
```

[Learn how to work with Git Submodules](https://tug.ro/blog/git-demystified/#submodules).

## Requirements

```sh
# Install Homebrew
# https://brew.sh/

# Install Docker Desktop on Mac
# https://docs.docker.com/desktop/install/mac-install/

brew update  # Update brew
brew upgrade  # Upgrade packages

# Install necessary tools
brew install jq

# Install mkcert to create and manage dev CA certificates locally
brew install mkcert

# Install `keytool` which we use to create TLS certificates for Kafka
# NOTE: Carefully follow the instructions generated during running the next step
brew install openjdk
```

## Pre-Install

NOTE: You should need to run these steps only once a year.

- Setup `.env`

```sh
# Copy .env.example to .env
cp .env.example .env

# Fill .env with relevant details
# If you're feeling lost, please ask someone who knows!
```

- Setup dev CA certificates

```sh
# Install a new development Certificate Authority on your machine
export CAROOT=~/.local/share/mkcert
# NOTE: Carefully follow the instructions generated during running the next step
mkcert -install

# Generate a new certificate for local.dev
pushd ~/.local/share/mkcert
mkdir local.dev && cd local.dev
mkcert "*.local.dev"
popd
```

- Create aliases

```sh
# bash users
echo "alias dc=\"docker compose\"" >> ~/.bash_profile

# zsh users
echo "alias dc=\"docker compose\"" >> ~/.zshenv
```

## Install

NOTE: You should need to run these steps only once a quarter.

```sh
# Merge certifi's CA bundle with mkcert's Root CA. The resulting file
# will be provided as REQUESTS_CA_BUNDLE to python-requests package.
./bin/merge_certifi_cabundle_and_mkcert_rootca.sh

# Generate TLS certificates for Kafka and store in a keystore file
./bin/create_kafka_tls_certificates.sh
```

## Run

```sh
# Bring all containers up and running
dc up -d  # If this command fails, check if you've aliased dc to "docker compose"
```

## Troubleshooting

```sh
# If you ever encounter this error when running any command, then run the below
# export command in your terminal first.
# > ssl.SSLError: [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed

# OpenSSL uses this environment variable to look for root CA certificates.
# Used in looking up our Kafka's root CA.
export SSL_CERT_FILE=~/.local/share/mkcert/certifi_plus_mkcert_cacert.pem
```
