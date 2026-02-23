# Generate mTLS trust store p12
KEYCLOAK_TRUSTSTORE_PASS="${KEYCLOAK_TRUSTSTORE_PASS:-changeit}"
ROOT_TRUSTSTORE_PATH="${ROOT_TRUSTSTORE_PATH:-/truststore/root_ca.p12}"
ROOT_CA_PATH="${ROOT_CA_PATH:-/mnt/ca/certs/root_ca.crt}"
INTERMEDIATE_CA_PATH="${INTERMEDIATE_CA_PATH:-/mnt/ca/certs/intermediate_ca.crt}"

if [ ! -f "$ROOT_CA_PATH" ]; then
  echo "Root CA cert not found at $ROOT_CA_PATH"
  exit 1
fi

echo "Building PKCS12 truststore from $ROOT_CA_PATH"
keytool -importcert -noprompt \
  -storetype PKCS12 \
  -keystore "$ROOT_TRUSTSTORE_PATH" \
  -storepass "$KEYCLOAK_TRUSTSTORE_PASS" \
  -alias root_ca \
  -file "$ROOT_CA_PATH"

keytool -importcert -noprompt \
  -storetype PKCS12 \
  -keystore "$ROOT_TRUSTSTORE_PATH" \
  -storepass "$KEYCLOAK_TRUSTSTORE_PASS" \
  -alias intermediate_ca \
  -file "$INTERMEDIATE_CA_PATH"

echo "Truststore created at $ROOT_TRUSTSTORE_PATH"
keytool -list -v \
  -storetype PKCS12 \
  -keystore "$ROOT_TRUSTSTORE_PATH" \
  -storepass "$KEYCLOAK_TRUSTSTORE_PASS" | head -n 20

# Generate keycloak server certificate
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout /truststore/keycloak-server-cert.key \
  -out /truststore/keycloak-server-cert.crt \
  -subj "/CN=keycloak" \
  -addext "subjectAltName=DNS:keycloak,DNS:localhost,IP:127.0.0.1"

openssl pkcs12 -export \
  -inkey /truststore/keycloak-server-cert.key \
  -in /truststore/keycloak-server-cert.crt \
  -out /truststore/keycloak-server-cert.p12 \
  -name server \
  -password pass:$KEYCLOAK_TRUSTSTORE_PASS