# -------------------------------------------------------------------------
# Consul Parameters (Keys) Lookup Table for Functions in Package
# -------------------------------------------------------------------------

#' @keywords internal
func_list <- list(

  # conn to MySQL database
  est_mysql_conn = c(
    "username",
    "password",
    "host",
    "port",
    "database"
  ),

  # conn to Postgres database
  est_pgres_conn = c(
    "username",
    "password",
    "host",
    "port",
    "database"
  ),

  # conn to Mongo database
  est_mongo_conn = c(
    "username",
    "password",
    "host",
    "port",
    "database",
    "collection"
  ),

  # reverse SSH tunnel
  reverse_proxy = c(
    "username",
    "port",
    "remotehost",
    "remoteport",
    "farawayhost",
    "farawayport"
  ),

  # download sheet from source
  download_sheet = c(
    "username",
    "password"
  )
)
