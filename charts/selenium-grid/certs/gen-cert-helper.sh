#!/bin/bash
# README: This script is used to generate a self-signed certificate for enabling HTTPS/TLS in Selenium Grid

# Initialize default values
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
DIRECTORY_PATH=$SCRIPT_DIR
# Parse command-line options
# -d directory_path: Specify the directory path to store the generated certificate files
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

CERTNAME=${CERTNAME:-tls}
STOREPASS=${STOREPASS:-"seleniumkeystore"}
KEYPASS=${KEYPASS:-$STOREPASS}
ALIAS=${ALIAS:-"SeleniumHQ"}
SERVER_KEYSTORE=${SERVER_KEYSTORE:-server.jks}
SERVER_KEYSTORE_PASSPWD=${SERVER_KEYSTORE_PASSPWD:-server.pass}
BASE64_ONLY=${BASE64_ONLY:-0}
if [ -n "${ADD_IP_ADDRESS}" ] && [ "${ADD_IP_ADDRESS}" = "hostname" ]; then
  ADD_IP_ADDRESS=",IP:$(hostname -I | awk '{print $1}')"
else
  ADD_IP_ADDRESS=${ADD_IP_ADDRESS}
fi

# Remove existing files
rm -f ${CERTNAME}.* ${SERVER_KEYSTORE}

# Create JKS (Java Keystore) - this is used to set for JAVA_OPTS -Djavax.net.ssl.trustStore=<path-to-jdk-mounted-in-container>
# The key pass set to JAVA_OPTS -Djavax.net.ssl.trustStorePassword=<password>
# Dummy cert without correct SAN, DNS, to skip hostname verification by JAVA_OPTS -Djdk.internal.httpclient.disableHostnameVerification=true
keytool -genkeypair \
    -alias ${ALIAS} \
    -keyalg RSA \
    -v \
    -dname "CN=SeleniumHQ,OU=Software Freedom Conservancy,O=SeleniumHQ,L=Unknown,ST=Unknown,C=Unknown" \
    -ext "SAN:c=DNS:localhost,DNS:selenium-grid.local,DNS:selenium-grid.prod,DNS:selenium.dev${ADD_IP_ADDRESS}" \
    -validity 3650 \
    -storepass ${STOREPASS} \
    -keypass ${KEYPASS} \
    -keystore ${SERVER_KEYSTORE}

if [ ${BASE64_ONLY} -eq 1 ]; then
  # Base64 encode JKS file (for Kubernetes Secret)
  base64 -i ${SERVER_KEYSTORE} -w 0 > ${SERVER_KEYSTORE}.base64
fi

echo -n "${STOREPASS}" > ${SERVER_KEYSTORE_PASSPWD}

if [ ${BASE64_ONLY} -eq 1 ]; then
  # Base64 encode JKS file (for Kubernetes Secret)
  base64 -i ${SERVER_KEYSTORE_PASSPWD} -w 0 > ${SERVER_KEYSTORE_PASSPWD}.base64
fi

# Create PKCS12 from JKS
keytool -importkeystore -srckeystore ${SERVER_KEYSTORE} \
   -destkeystore ${CERTNAME}.p12 \
   -srcstoretype jks \
   -storepass ${STOREPASS} -keypass ${KEYPASS} -srcstorepass ${STOREPASS} \
   -deststoretype pkcs12

# Create private key from PKCS12
openssl pkcs12 -nodes -in ${CERTNAME}.p12 -out ${CERTNAME}.key \
    -passin pass:${KEYPASS}

# Create private key PKCS8 format (this is used to set for option --https-private-key)
openssl pkcs8 -in ${CERTNAME}.key -topk8 -nocrypt -out ${CERTNAME}.pkcs8

# Remove source file PKCS12 (prevent sensitive data leak)
rm -f ${CERTNAME}.p12

# Rename PKCS8 file to .key extension (most compatible extension for private key)
mv ${CERTNAME}.pkcs8 ${CERTNAME}.key

if [ ${BASE64_ONLY} -eq 1 ]; then
  # Base64 encode PKCS8 file (for Kubernetes Secret)
  base64 -i ${CERTNAME}.key -w 0 > ${CERTNAME}.key.base64
fi

# Create certificate CRT from JKS (this is used to set for option --https-certificate)
keytool -exportcert -alias ${ALIAS} \
    -storepass ${STOREPASS} -keypass ${KEYPASS} \
    -keystore ${SERVER_KEYSTORE} -rfc -file ${CERTNAME}.crt

if [ ${BASE64_ONLY} -eq 1 ]; then
  # Base64 encode Certificate CRT file (for Kubernetes Secret)
  base64 -i ${CERTNAME}.crt -w 0 > ${CERTNAME}.crt.base64
fi

if [ ${BASE64_ONLY} -eq 1 ]; then
  rm -rf ${CERTNAME}.key
  rm -rf ${SERVER_KEYSTORE}
  rm -rf ${CERTNAME}.crt
fi

if [ -n "${DIRECTORY_PATH}" ]; then
  # Create the specified directory if it does not exist
  mkdir -p ${DIRECTORY_PATH}
  # Move the generated certificate files to the specified directory
  if [ ${BASE64_ONLY} -eq 1 ]; then
    mv ${SERVER_KEYSTORE}.base64 ${DIRECTORY_PATH}/
    mv ${SERVER_KEYSTORE_PASSPWD}.base64 ${DIRECTORY_PATH}/
    mv ${CERTNAME}.key.base64 ${DIRECTORY_PATH}/
    mv ${CERTNAME}.crt.base64 ${DIRECTORY_PATH}/
  else
    mv ${CERTNAME}.key ${DIRECTORY_PATH}/
    mv ${SERVER_KEYSTORE} ${DIRECTORY_PATH}/
    mv ${SERVER_KEYSTORE_PASSPWD} ${DIRECTORY_PATH}/
    mv ${CERTNAME}.crt ${DIRECTORY_PATH}/
  fi
  echo "Self-signed certificate files have been generated and stored in: ${DIRECTORY_PATH}"
fi
