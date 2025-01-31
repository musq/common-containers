#!/usr/bin/env sh

# Script to create a READ ONLY user with access to everything.
# This script gets executed only once, when starting postgres for the first time.
# Author: Ashish Ranjan

# ======================================================================

# Unofficial POSIX Shell Strict Mode
# https://gist.github.com/EvgenyOrekhov/5c1418f4710558b5d6717d9e69c6e929
set -o errexit
set -o nounset
IFS=$(printf '\n\t')

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

psql --variable ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  <<-EOSQL
    CREATE ROLE readonlyuser WITH LOGIN PASSWORD 'readonlyuser';
    GRANT pg_read_all_data TO readonlyuser;
EOSQL
