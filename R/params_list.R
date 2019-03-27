###############################################
########### Parameter Reference ###############
###############################################

params_list <- list(

  # mysql database
  mysql = c(
    "username",
    "password",
    "host",
    "port",
    "database"
  ),

  # postgres database
  pgres = c(
    "username",
    "password",
    "host",
    "port",
    "database"
  ),

  # mongo database
  mongo = c(
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
  )
)
