# ref: https://registry.terraform.io/providers/mrparkers/keycloak/4.1.0/docs/resources/openid_client

variable "app_name" {
  type    = string
  default = "nplintegrations"
}

variable "root_url" {
  type    = string
  default = "http://localhost:5173"
}

variable "valid_redirect_uris" {
  type = list(string)
  default = ["*"]
}

variable "valid_post_logout_redirect_uris" {
  type = list(string)
  default = ["+"]
}

variable "web_origins" {
  type = list(string)
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
  realm = var.app_name
  # Realm Settings > Login tab
  reset_password_allowed   = true
  login_with_email_allowed = true
  registration_allowed = true

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

  # Realm Settings > User profile tab
  attributes = {
    userProfileEnabled = true
  }
}

resource "keycloak_realm_user_profile" "userprofile" {
  realm_id = keycloak_realm.realm.id

  attribute {
    name         = "username"
    display_name = "Username"
  }

  attribute {
    name         = "firstName"
    display_name = "First Name"

    permissions {
      view = ["user", "admin"]
      edit = ["user", "admin"]
    }
  }

  attribute {
    name         = "lastName"
    display_name = "Last Name"

    permissions {
      view = ["user", "admin"]
      edit = ["user", "admin"]
    }
  }

  attribute {
    name = "email"

    permissions {
      view = ["admin"]
      edit = ["admin"]
    }
  }

  attribute {
    name         = "organization"
    display_name = "Organization"

    permissions {
      view = ["admin"]
      edit = ["admin"]
    }
  }

  attribute {
    name = "department"

    permissions {
      view = ["admin"]
      edit = ["admin"]
    }
  }
}

resource "keycloak_default_roles" "default_roles" {
  realm_id = keycloak_realm.realm.id
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
  root_url                        = var.root_url
}

resource "keycloak_openid_user_attribute_protocol_mapper" "party_mapper" {
  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.client.id
  name      = "party-mapper"

  user_attribute   = "party"
  claim_name       = "party"
  claim_value_type = "JSON"
}

resource "keycloak_openid_user_attribute_protocol_mapper" "organization_mapper" {
  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.client.id
  name      = "organization-mapper"

  user_attribute   = "organization"
  claim_name       = "organization"
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

resource "keycloak_user" "alice" {
  realm_id   = keycloak_realm.realm.id
  depends_on = [keycloak_realm_user_profile.userprofile]
  username   = "alice"
  email      = "alice@nd.tech"
  first_name = "Alice"
  last_name  = "A"

  attributes = {
    "organization" = jsonencode(["NDtech"])
    "department" = jsonencode(["acquisitions"])
  }

  initial_password {
    value     = "alice"
    temporary = false
  }
}

resource "keycloak_user" "bob" {
  realm_id   = keycloak_realm.realm.id
  depends_on = [keycloak_realm_user_profile.userprofile]
  username   = "bob"
  email      = "bob@nd.tech"
  first_name = "Bob"
  last_name  = "B"

  attributes = {
    "organization" = jsonencode(["NDtech"])
    "department" = jsonencode(["business"])
  }

  initial_password {
    value     = "bob"
    temporary = false
  }
}

resource "keycloak_user" "charlie" {
  realm_id   = keycloak_realm.realm.id
  depends_on = [keycloak_realm_user_profile.userprofile]
  username   = "charlie"
  email      = "charlie@nd.tech"
  first_name = "Charlie"
  last_name  = "C"

  attributes = {
    "organization" = jsonencode(["NDtech"])
    "department" = jsonencode(["consulting"])
  }
  initial_password {
    value     = "charlie"
    temporary = false
  }
}

resource "keycloak_user" "eve" {
  realm_id   = keycloak_realm.realm.id
  depends_on = [keycloak_realm_user_profile.userprofile]
  username   = "eve"
  email      = "eve@evilcorp.com"
  first_name = "Eve"
  last_name  = "E"
  attributes = {
    "organization" = jsonencode(["EvilCorp"])
    "department" = jsonencode(["eavesdropping"])
  }
  initial_password {
    value     = "eve"
    temporary = false
  }
}
