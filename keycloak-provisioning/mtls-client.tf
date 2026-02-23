resource "keycloak_openid_client" "mtls_cert_bound" {
  realm_id  = keycloak_realm.realm.id
  client_id = "mTLS"
  name      = "mTLS client"

  standard_flow_enabled        = false
  implicit_flow_enabled        = false
  direct_access_grants_enabled = false
  service_accounts_enabled     = true

  access_type = "CONFIDENTIAL"

  client_authenticator_type = "mtls-x509-with-sans"

  extra_config = {
    "x509.subjectdn" = "^CN=npl_integrations"
  }
}

resource "keycloak_openid_client_default_scopes" "mtls_cert_bound" {
  realm_id       = keycloak_realm.realm.id
  client_id      = keycloak_openid_client.mtls_cert_bound.id
  default_scopes = []
}

resource "keycloak_openid_client_optional_scopes" "mtls_cert_bound" {
  realm_id        = keycloak_realm.realm.id
  client_id       = keycloak_openid_client.mtls_cert_bound.id
  optional_scopes = []
}

resource "keycloak_generic_protocol_mapper" "san_uri_to_roles" {
  realm_id        = keycloak_realm.realm.id
  client_id       = keycloak_openid_client.mtls_cert_bound.id
  name            = "X.509 SANs URI to roles"
  protocol        = "openid-connect"
  protocol_mapper = "san-uri-to-roles"
  config = {}
}