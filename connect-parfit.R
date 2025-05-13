# Quick script for establishing parfit connection
# Requires: RPostgres, DBI

pacman::p_load(RPostgres, DBI, keyring)

# Check credentials exist, otherwise prompt user to input

# If no parfit user get parfit user
if (nrow(key_list("parfit_user")) == 0) {
  key_set("parfit_user",prompt = "Parfit access uername:")
}

# If no parfit password get parfit password
if (nrow(key_list("parfit_password")) == 0) {
  key_set("parfit_password",prompt = "User Parfit access password:")
}

# If no parfit host get parfit host
if (nrow(key_list("parfit_host")) == 0) {
  key_set("parfit_host",prompt = "Parfit host URL:")
}


message("Using stored credentials for authentication.")

# Create the connection
con <- RPostgres::dbConnect(
  RPostgres::Postgres(),
  host = key_get("parfit_host"),,
  port = 5432,
  dbname = "parfit",
  user = key_get("parfit_user"), 
  password = key_get("parfit_password")
)

