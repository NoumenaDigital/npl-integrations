terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = ">= 5.0.0"
    }
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  base_path = ""
}
