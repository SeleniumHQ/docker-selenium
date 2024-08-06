#!/bin/bash

echo "$(whoami) is running cert script!"

# Initialize default values
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
DIRECTORY_PATH=$SCRIPT_DIR
# Parse command-line options
# -d directory_path: Specify the directory path contains the JKS files for importing
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
is_valid_jks() {
  local jks=$1
  keytool -list -keystore $jks -storepass ${JKS_PASS} > /dev/null 2>&1
  return $?
}

# Function to check if a certificate is present in the cacerts file
is_cert_in_cacerts() {
  local alias=$1
  local cacerts_file=$2
  local cacerts_pass=$3
  keytool -list -keystore "$cacerts_file" -storepass "$cacerts_pass" | grep -iq "$alias"
  return $?
}

on_exit() {
  rm -f ${OUTPUT_PEM}
}
trap on_exit EXIT

JKS_FILE="${DIRECTORY_PATH}/${JKS_FILE:-"server.jks"}" # JKS file name
JKS_PASS_FILE="${JKS_PASS_FILE:-"server.pass"}" # Trust store password file (or password plain text)
JAVA_CACERTS_PATH=${JAVA_CACERTS_PATH:-"/etc/ssl/certs/java/cacerts"} # Target java cacerts file
CACERTS_PASS=${CACERTS_PASS:-"changeit"} # Password for the java cacerts file
ALIAS=${ALIAS:-"SeleniumHQ"} # Alias to be used in the trust store
OUTPUT_PEM=${OUTPUT_PEM:-"/tmp/${ALIAS}.pem"} # Output PEM file

# Get the list of certs copied
jks_files=($(ls ${DIRECTORY_PATH}))

if [ -f "${DIRECTORY_PATH}/${JKS_PASS_FILE}" ]; then
  JKS_PASS=$(cat "${DIRECTORY_PATH}/${JKS_PASS_FILE}")
else
  JKS_PASS=${JKS_PASS_FILE}
fi

for jks_file in "${jks_files[@]}"; do
  jks_file="${DIRECTORY_PATH}/${jks_file}"
  if ! is_valid_jks "${jks_file}"; then
    continue
  else
    echo "Processing ${jks_file}"
  fi
  # Export certificate from JKS to PEM format
  keytool -export -alias ${ALIAS} -file ${OUTPUT_PEM} -keystore ${jks_file} -storepass ${JKS_PASS} -noprompt

  # Delete the existing alias if it exists
  sudo keytool -delete -alias ${ALIAS} -keystore ${JAVA_CACERTS_PATH} -storepass ${CACERTS_PASS} -noprompt || true

  # Import the PEM certificate into the java cacerts keystore
  sudo mkdir -p $(dirname ${JAVA_CACERTS_PATH})
  sudo keytool -import -trustcacerts -alias ${ALIAS} -file ${OUTPUT_PEM} -keystore ${JAVA_CACERTS_PATH} -storepass ${CACERTS_PASS} -noprompt

  # Check if the certificate is present in the cacerts file
  if is_cert_in_cacerts ${ALIAS} ${JAVA_CACERTS_PATH} ${CACERTS_PASS}; then
    echo "The certificate with alias ${ALIAS} is present in ${JAVA_CACERTS_PATH}"
  else
    echo "The certificate with alias ${ALIAS} is NOT present in ${JAVA_CACERTS_PATH}"
    exit 1
  fi
done
