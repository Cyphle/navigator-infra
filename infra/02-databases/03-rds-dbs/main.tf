# Create Navigator database
resource "postgresql_database" "navigator" {
  name              = "navigator"
  owner             = "postgres"
  template          = "template0"
  encoding          = "UTF8"
  lc_collate        = "en_US.UTF-8"
  lc_ctype          = "en_US.UTF-8"
  connection_limit  = -1
  allow_connections = true

  depends_on = [data.aws_db_instance.main]
}

# Create Keycloak database
resource "postgresql_database" "keycloak" {
  name              = "keycloak"
  owner             = "postgres"
  template          = "template0"
  encoding          = "UTF8"
  lc_collate        = "en_US.UTF-8"
  lc_ctype          = "en_US.UTF-8"
  connection_limit  = -1
  allow_connections = true

  depends_on = [data.aws_db_instance.main]
}

# Create Navigator user
resource "postgresql_role" "navigator_user" {
  name     = "navigator_user"
  login    = true
  password = local.db_creds.navigator_password

  depends_on = [postgresql_database.navigator]
}

# Create Keycloak user
resource "postgresql_role" "keycloak_user" {
  name     = "keycloak_user"
  login    = true
  password = local.db_creds.keycloak_password

  depends_on = [postgresql_database.keycloak]
}

# Grant permissions to Navigator user on Navigator database
resource "postgresql_grant" "navigator_grant" {
  database    = postgresql_database.navigator.name
  role        = postgresql_role.navigator_user.name
  privileges  = ["ALL"]
  object_type = "database"
}

# Grant permissions to Keycloak user on Keycloak database
resource "postgresql_grant" "keycloak_grant" {
  database    = postgresql_database.keycloak.name
  role        = postgresql_role.keycloak_user.name
  privileges  = ["ALL"]
  object_type = "database"
}