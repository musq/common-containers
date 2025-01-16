#!/usr/bin/env sh

# Script to create Meta DB when starting common_postgres for the first time
# Author: Ashish Ranjan

# ======================================================================

# Unofficial POSIX Shell Strict Mode
# https://gist.github.com/EvgenyOrekhov/5c1418f4710558b5d6717d9e69c6e929
set -o errexit
set -o nounset
IFS=$(printf '\n\t')

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

META_DB="meta"

psql --variable ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  <<-EOSQL
    CREATE DATABASE "$META_DB" WITH
        ENCODING='UTF8'
        LC_COLLATE='en_US.utf8'
        LC_CTYPE='en_US.utf8';
EOSQL
