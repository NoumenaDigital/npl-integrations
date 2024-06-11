# ref: https://registry.terraform.io/providers/mrparkers/keycloak/4.1.0/docs/resources/openid_client

variable "default_password" {
  type = string
}

variable "app_name" {
  type = string
  default = "nplintegrations"
}

/*
variable "root_url" {
  type    = string
  default = "http://127.0.0.1:5173"
}
*/

variable "base_url" {
  type    = string
  default = "http://localhost:3000"
}

variable "valid_redirect_uris" {
  type    = list(string)
  default = ["*"]
}

variable "valid_post_logout_redirect_uris" {
  type    = list(string)
  default = ["+"]
}

variable "web_origins" {
  type    = list(string)
  default = ["*"]
}

variable "realm_smtp_from" {
  type    = string
  default = "payee1@noumenadigital.com"
}

variable "realm_smtp_host" {
  type    = string
  default = "smtp.gmail.com"
}

variable "realm_smtp_port" {
  type    = number
  default = 465
}

variable "realm_smtp_auth_username" {
  type    = string
  default = "payee1@noumenadigital.com"
}

variable "realm_smtp_auth_password" {
  type    = string
  default = ""
}

variable "systemuser_secret" {
  type    = string
}

variable "systemuser_name" {
  type    = string
  default = "bankingsystem"
}

resource "keycloak_realm" "realm" {
  realm                    = var.app_name
  # Realm Settings > Login tab
  reset_password_allowed   = true
  login_with_email_allowed = true
  # Realm Settings > Email tab
  smtp_server {
    from = var.realm_smtp_from
    host = var.realm_smtp_host
    port = var.realm_smtp_port
    ssl  = true

    auth {
      username = var.realm_smtp_auth_username
      password = var.realm_smtp_auth_password
    }
  }

  security_defenses {
    headers {
      content_security_policy = ""
    }
  }
}

resource "keycloak_default_roles" "default_roles" {
  realm_id      = keycloak_realm.realm.id
  default_roles = ["offline_access", "uma_authorization"]
}

resource "keycloak_openid_client" "client" {
  realm_id                        = keycloak_realm.realm.id
  client_id                       = var.app_name
  access_type                     = "PUBLIC"
  direct_access_grants_enabled    = true
  standard_flow_enabled           = true
  valid_redirect_uris             = var.valid_redirect_uris
  valid_post_logout_redirect_uris = var.valid_post_logout_redirect_uris
  web_origins                     = var.web_origins
  root_url                        = "http://localhost:5173"
}

resource "keycloak_openid_user_attribute_protocol_mapper" "party_mapper" {
  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.client.id
  name      = "party-mapper"

  user_attribute   = "party"
  claim_name       = "party"
  claim_value_type = "JSON"
}

resource "keycloak_openid_user_attribute_protocol_mapper" "department_mapper" {
  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.client.id
  name      = "department-mapper"

  user_attribute   = "department"
  claim_name       = "department"
  claim_value_type = "JSON"
}

resource "keycloak_openid_user_attribute_protocol_mapper" "job_title_mapper" {
  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.client.id
  name      = "job-title-mapper"

  user_attribute   = "job_title"
  claim_name       = "job_title"
  claim_value_type = "JSON"
}

resource "keycloak_openid_user_attribute_protocol_mapper" "organisation_mapper" {
  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.client.id
  name      = "organisation-mapper"

  user_attribute   = "organisation"
  claim_name       = "organisation"
  claim_value_type = "JSON"
}

resource "keycloak_user" "alice" {
  realm_id   = keycloak_realm.realm.id
  username   = "alice"
  email      = "alice@noumenadigital.com"
  first_name = "Alice"
  last_name  = "Noumena"
  attributes = {
    "job_title" = jsonencode(["chairperson"])
    "organisation" = jsonencode(["Noumena"])
    "department" = jsonencode(["business"])
  }
  initial_password {
    value     = "alice"
    temporary = false
  }
}

resource "keycloak_user" "bob" {
  realm_id   = keycloak_realm.realm.id
  username   = "bob"
  email      = "bob@noumenadigital.com"
  first_name = "Bob"
  last_name  = "Noumena"
  attributes = {
    "job_title" = jsonencode(["board-member", "secretary"])
    "organisation" = jsonencode(["Noumena"])
    "department" = jsonencode(["tech"])
  }
  initial_password {
    value     = "bob"
    temporary = false
  }
}

resource "keycloak_user" "eve" {
  realm_id   = keycloak_realm.realm.id
  username   = "eve"
  email      = "eve@noumenadigital.com"
  first_name = "Eve"
  last_name  = "Noumena"
  attributes = {
    "job_title" = jsonencode(["board-member"])
    "organisation" = jsonencode(["TableOrg"])
    "department" = jsonencode(["business"])
  }
  initial_password {
    value     = "eve"
    temporary = false
  }
}
