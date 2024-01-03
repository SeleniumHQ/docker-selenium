# README: This script is used to generate a self-signed certificate for enabling HTTPS/TLS in Selenium Grid

CERTNAME=${1:-selenium}
STOREPASS=${2:-changeit}
KEYPASS=${3:-changeit}
ALIAS=${4:-SeleniumHQ}
BASE64_ONLY=1

# Remove existing files
rm -f ${CERTNAME}.*

# Create JKS (Java Keystore) - this is used to set for JAVA_OPTS -Djavax.net.ssl.trustStore=<path-to-jdk-mounted-in-container>
# The key pass set to JAVA_OPTS -Djavax.net.ssl.trustStorePassword=<password>
# Dummy cert without correct SAN, DNS, to skip hostname verification by JAVA_OPTS -Djdk.internal.httpclient.disableHostnameVerification=true
keytool -genkeypair \
    -alias ${ALIAS} \
    -keyalg RSA \
    -v \
    -dname "CN=SeleniumHQ,OU=Software Freedom Conservancy,O=SeleniumHQ,L=Unknown,ST=Unknown,C=Unknown" \
    -ext "SAN:c=DNS:localhost,DNS:selenium-grid.local" \
    -validity 3650 \
    -storepass ${STOREPASS} \
    -keypass ${KEYPASS} \
    -keystore ${CERTNAME}.jks

# Base64 encode JKS file (for Kubernetes Secret)
#base64 -i ${CERTNAME}.jks -w 0 > ${CERTNAME}.jks.base64

# Create PKCS12 from JKS
keytool -importkeystore -srckeystore ${CERTNAME}.jks \
   -destkeystore ${CERTNAME}.p12 \
   -srcstoretype jks \
   -storepass ${STOREPASS} -keypass ${KEYPASS} -srcstorepass ${STOREPASS} \
   -deststoretype pkcs12

# Create private key PEM from PKCS12
openssl pkcs12 -nodes -in ${CERTNAME}.p12 -out ${CERTNAME}.key \
    -passin pass:${KEYPASS}

# Create private key PKCS8 format (this is used to set for option --https-private-key)
openssl pkcs8 -in ${CERTNAME}.key -topk8 -nocrypt -out ${CERTNAME}.pkcs8

# Base64 encode PKCS8 file (for Kubernetes Secret)
base64 -i ${CERTNAME}.pkcs8 -w 0 > ${CERTNAME}.pkcs8.base64

# Create certificate PEM from JKS (this is used to set for option --https-certificate)
keytool -exportcert -alias ${ALIAS} \
    -storepass ${STOREPASS} -keypass ${KEYPASS} \
    -keystore ${CERTNAME}.jks -rfc -file ${CERTNAME}.pem

# Base64 encode Certificate PEM file (for Kubernetes Secret)
#base64 -i ${CERTNAME}.pem -w 0 > ${CERTNAME}.pem.base64

if [ ${BASE64_ONLY} -eq 1 ]; then
  # Remove source files (prevent sensitive data leak)
  rm -f ${CERTNAME}.key
  rm -f ${CERTNAME}.p12
  rm -f ${CERTNAME}.pkcs8
  # Retain ${CERTNAME}.jks for Java client establishing HTTPS connection
  # Retain ${CERTNAME}.pem for client establishing HTTPS connection
fi
