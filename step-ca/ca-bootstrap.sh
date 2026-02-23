# Generate JWK for the step-ca provisioner
KEYCLOAK_TRUSTSTORE_PASS="${KEYCLOAK_TRUSTSTORE_PASS:-changeit}"
TMP_DIRECTORY="$(mktemp -d "${HOME}/jwk.XXXXXX")"
PRIVATE_JWK="${TMP_DIRECTORY}/priv.json"
PUBLIC_JWK="${TMP_DIRECTORY}/pub.json"

step crypto jwk create "${PUBLIC_JWK}" "${PRIVATE_JWK}" --no-password --insecure >/dev/null

chmod 644 "${PRIVATE_JWK}"
cp "${PRIVATE_JWK}" "/home/step/prv.json"

cp "${PUBLIC_JWK}" "/home/step/pub.json"
chmod 644 "/home/step/pub.json"

echo "JWK generated for step-ca provisioner"

# Generate issuer certificate
ROOT_CA="/mnt/ca/certs/root_ca.crt"
CA_FINGERPRINT="$(step certificate fingerprint $ROOT_CA | tr -d '\r\n')"
echo "Fingerprint: $CA_FINGERPRINT"

step ca bootstrap --ca-url https://step-ca:9000 --fingerprint "$CA_FINGERPRINT" --force

RESPONSE="$(curl -s --cacert "$ROOT_CA" https://step-ca:9000/health)"
if [ "$RESPONSE" != '{"status":"ok"}' ]; then
  echo "step-ca health check failed: $RESPONSE"
  exit 1
fi

ADMIN_PW_FILE="$HOME/secrets/dev-admin-password-file.txt"
if [ ! -f "$ADMIN_PW_FILE" ]; then
  echo "Missing $ADMIN_PW_FILE"; exit 1
fi

ADMIN_PROVISIONER=$DOCKER_STEPCA_INIT_PROVISIONER_NAME
ADMIN_SUBJECT=$DOCKER_STEPCA_INIT_ADMIN_SUBJECT
JWK_PROVISIONER_NAME="jwk-provisioner"

step ca provisioner add "$JWK_PROVISIONER_NAME" --type JWK \
  --public-key "/home/step/pub.json" \
  --admin-subject "$ADMIN_SUBJECT" \
  --admin-provisioner "$ADMIN_PROVISIONER" \
  --admin-password-file "$ADMIN_PW_FILE" \
  --ca-url https://step-ca:9000 \
  --root "$ROOT_CA"

step ca provisioner list

KID="$(grep -o '"kid"[^,}]*' "/home/step/pub.json" | sed -E 's/.*"kid" *: *"([^"]*)".*/\1/')"
[ -n "$KID" ] || { echo "ERROR: pub.json missing kid"; exit 1; }

TOKEN="$(step ca token "$ADMIN_SUBJECT" \
  --provisioner "$JWK_PROVISIONER_NAME" \
  --key "/home/step/prv.json" \
  --kid "$KID" \
  --ca-url "https://step-ca:9000" \
  --san "URI:role://issuer" \
  --root "$ROOT_CA")"

step ca certificate "$ADMIN_SUBJECT" \
  "/mnt/ca/certs/issuer.crt" \
  "/mnt/ca/certs/issuer.key" \
  --token "$TOKEN" \
  --ca-url "https://step-ca:9000" \
  --root "$ROOT_CA" \
  --kty EC --curve P-256

step crypto key format /mnt/ca/certs/issuer.key \
  --out /mnt/ca/certs/issuer-pkcs8.pem \
  --pkcs8 --pem --no-password --insecure

echo "Issuer certificate and client key created"