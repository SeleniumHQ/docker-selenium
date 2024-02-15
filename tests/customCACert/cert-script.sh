#!/bin/bash
set -x

echo "$(whoami) is running cert script!"

CERT_DIR=${1:-"/usr/share/ca-certificates/extra/"}
TRUST_ATTR=${2:-"TCu,Cu,Tu"}

# Get the list of certs copied
cert_files=($(ls $CERT_DIR))

# Find all "cert9.db" files
cert_db_files=($(find ${HOME}/ -name "cert9.db"))

for cert_file in "${cert_files[@]}"; do
  cert_file="${CERT_DIR}/${cert_file}"
  file_name=$(basename $cert_file)
  cert_name="${file_name%.*}"
  for cert_db_file in "${cert_db_files[@]}"; do
    cert_db_path=$(dirname $cert_db_file)
    certutil -d "sql:${cert_db_path}" -A -t "${TRUST_ATTR}" -n "${cert_name}" -i "${cert_file}"
    certutil -L -d "sql:${cert_db_path}" -n "${cert_name}"
  done
done
