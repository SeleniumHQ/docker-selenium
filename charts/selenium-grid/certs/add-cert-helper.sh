#!/bin/bash

echo "$(whoami) is running cert script!"

# Initialize default values
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
DIRECTORY_PATH=$SCRIPT_DIR
# Parse command-line options
# -d directory_path: Specify the directory path contains the certs for importing
while getopts "d:" opt; do
  case ${opt} in
    d )
      DIRECTORY_PATH=$OPTARG
      ;;
    \? )
      echo "Usage: cmd [-d directory_path]"
      exit 1
      ;;
  esac
done

# Shift out the option and argument to leave only the positional parameters
shift $((OPTIND-1))

# Function to check if a file is a valid certificate
is_valid_cert() {
  local cert_file=$1
  openssl x509 -in "$cert_file" -noout -text -passin pass: > /dev/null 2>&1
  return $?
}

# Function to check if a certificate is present in the ca-certificates.crt file
is_cert_in_bundle() {
  local bundle_file=$1
  local cert_file=$2
  openssl verify -CAfile $bundle_file $cert_file
  return $?
}

append_private_key_if_exists() {
  local cert_file=$1
  if [ -f "${cert_file%.crt}.key" ]; then
    cat ${cert_file} "${cert_file%.crt}.key" > $APPEND_CRT_KEY
    echo $APPEND_CRT_KEY
  else
    echo $cert_file
  fi
}

on_exit() {
  rm -f ${APPEND_CRT_KEY}
}
trap on_exit EXIT

TRUST_ATTR=${1:-"TCu,Cu,Tu"} # 1st argument is the trust attributes
TARGET_CERT_DIR=${TARGET_CERT_DIR:-"/usr/local/share/ca-certificates"} # Target directory to copy the certs
BUNDLE_CA_CERTS=${BUNDLE_CA_CERTS:-"/etc/ssl/certs/ca-certificates.crt"} # Bundle CA certificates
NSSDB_HOME=${NSSDB_HOME:-"${HOME}/.pki/nssdb"} # Default location of the NSSDB
APPEND_CRT_KEY="/tmp/tls.crt"
ALIAS_PREFIX=${ALIAS_PREFIX:-"SeleniumHQ"}

sudo mkdir -p ${TARGET_CERT_DIR}

# Get the list of certs copied
cert_files=($(ls ${DIRECTORY_PATH}))

# Find all "cert9.db" files
cert_db_files=($(find ${NSSDB_HOME} -name "cert*.db"))

for cert_file in "${cert_files[@]}"; do
  cert_file=$(readlink -f "${DIRECTORY_PATH}/${cert_file}")
  if ! is_valid_cert $cert_file; then
    continue
  else
    echo "Processing $cert_file"
  fi
  ALIAS="${ALIAS_PREFIX}_$(basename $cert_file)"
  cert_file=$(append_private_key_if_exists $cert_file)
  for cert_db_file in "${cert_db_files[@]}"; do
    echo "Adding to db: $cert_db_file"
    cert_db_path=$(dirname $cert_db_file)
    # Delete the alias if it exists
    certutil -D -d "sql:${cert_db_path}" -n "${ALIAS}"
    certutil -d "sql:${cert_db_path}" -A -t "${TRUST_ATTR}" -n "${ALIAS}" -i "${cert_file}"
    certutil -L -d "sql:${cert_db_path}" -n "${ALIAS}"
  done
  # Update the CA certificates, pick up the new certs under ${TARGET_CERT_DIR}
  sudo cp -f $cert_file "${TARGET_CERT_DIR}/${ALIAS}.crt"
  sudo update-ca-certificates --fresh
  # Check if the certificate is present in the bundle
  if is_cert_in_bundle ${BUNDLE_CA_CERTS} $cert_file; then
    echo "The certificate $cert_file is present in ${BUNDLE_CA_CERTS}"
  else
    echo "The certificate $cert_file is NOT present in ${BUNDLE_CA_CERTS}"
    exit 1
  fi
done
