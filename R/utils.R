# Read from Consul --------------------------------------------------------

#' Obtain Key / Value from Consul
#' @description See https://www.consul.io/ for more about Consul.
#'
#' @param key Key name to retrieve
#' @param path Path name to retrieve
#' @param ... One or many keys under path to retrieve.
#' All but path name will be coersed into a list.
#'
#' @return
#' Decoded value retrieved from Consul. 'NA' if empty.
#'
#' @importFrom magrittr %>%
#' @importFrom httr GET content
#' @importFrom base64enc base64decode
#' @export
#' @rdname get_kv
#'
#' @examples
#' \dontrun{
#'
#' # Return a string
#' get_kv("fruit/apple")
#'
#' # Return a list of values
#' get_batch_kv("fruit", c("apple", "banana", "coconut"))
#' # This works too
#' get_batch_kv("fruit", "apple", "banana", "coconut")
#'
#' }
#'
get_kv <- function(key) {

  # required paramters
  params <- c("host", "port", "swagger")

  # defensive
  if(!all(params %in% ls(envir = consul))) {
    stop("One or more Consul parameters cannot be found.")
  }

  # form url
  url <- sprintf("http://%s:%s/%s/%s", consul$host, consul$port, consul$swagger, key)

  # send request
  res <- GET(url) %>% content()

  # if return empty
  if(!length(res) > 0) {
    return(NA)
  }

  # extract value and decode
  tryCatch(
    res[[1]]$Value %>% base64enc::base64decode() %>% rawToChar(),
    error = function(e) { print(e); NA }
  )

}

#' @export
#' @rdname get_kv
get_batch_kv <- function(path, ...) {

  # required paramters
  params <- c("host", "port", "swagger")

  # check if `consul` exists

  # defensive
  if(!all(params %in% ls(envir = consul))) {
    stop("One or more Consul parameters cannot be found.")
  }

  # forming url
  url <- sprintf("http://%s:%s/%s/%s?recurse", consul$host, consul$port, consul$swagger, path)

  # send GET request
  res <- GET(url) %>% content()

  # if return empty
  if (!length(res) > 0) {
    return(NULL)
  }

  # first on list is folder/, not useful
  res[[1]] <- NULL

  # from Consul
  consul.k <- sapply(res, function(x) x[["Key"]])

  # from user
  user.k <- sapply(list(...), function(x) paste0(path, "/", x))

  # extract value based on keys specified by user
  encoded_vals <- sapply(user.k, function(x) {
    tryCatch(
      res[[which(consul.k == x)]]["Value"],
      error = function(e) "JQ=="
    )
  })

  # decode
  vals <- lapply(encoded_vals, function(x) {
    if(!is.na(x)) {
      tryCatch(
        rawToChar(base64enc::base64decode(x)),
        error = function(e) NA
      )}
  })

  # format names of list
  names(vals) <- names(vals) %>%
    gsub(pattern = "^\\w*/", replacement = "") %>%
    gsub(pattern = "\\.\\w+", replacement = "")

  # return
  vals

}


# Establish Connection to Common Database ---------------------------------

#' Establish Connection to Common Databases
#'
#' @name est_some_conn
#' @description Fetch credentials from Consul K/V store and establish connection to database.
#'
#' Required values for respective database:
#'
#'   \code{MySQL, PostgreSQL}
#'   \itemize{
#'   \item username
#'   \item password
#'   \item host
#'   \item port
#'   \item database
#'   }
#'
#'   \code{MongoDB}
#'   \itemize{
#'   \item username
#'   \item password
#'   \item host
#'   \item port
#'   \item database
#'   \item \strong{collection}
#'   }
#'
#' @param db Database to connect to
#' @param drv Database driver
#'
#' @return
#' Database connection if successful.
#'
#' @importFrom DBI dbConnect
#'
#' @examples
#' \dontrun{
#' est_mysql_conn('mysql_database')
#' est_pgres_conn('postgres_database')
#' est_mongo_conn('mongo_database')
#' }
est_some_conn <- function(db, drv) {

  # required parameters to establish connection
  params <- c("username", "password", "host", "port", "database")

  # fetch credentials
  db_config <- get_batch_kv(db, params)

  # check if all required params are specified
  if(!all(params %in% names(db_config))){
    stop("One or more MySQL parameters is missing")
  }

  # est conn
  c <- DBI::dbConnect(
    drv,
    user = db_config[["username"]],
    password = db_config[["password"]],
    host = db_config[["host"]],
    port = as.numeric(db_config[["port"]]),
    db = db_config[["database"]]
  )

  # return connection
  return(c)

}

#' @importFrom RMariaDB MariaDB
#' @export
#' @rdname est_some_conn
est_mysql_conn <- function(database, driver = RMariaDB::MariaDB()) {
  est_some_conn(database, driver)
}

#' @importFrom RPostgreSQL PostgreSQL
#' @export
#' @rdname est_some_conn
est_pgres_conn <- function(db, drv = RPostgreSQL::PostgreSQL()) {
  est_some_conn(db, drv)
}


#' @importFrom mongolite mongo
#' @export
#' @rdname est_some_conn
est_mongo_conn <- function(db) {

  # required parameters to establish connection
  params <- c("username", "password", "host", "port", "database", "collection")

  # fetch mongo credentials
  mg_config <- get_batch_kv(db, params)

  # check if the credentials are specified
  if(!all(params %in% names(mg_config))){
    stop("One or more Mongo parameters is missing")
  }

  # est conn
  c <- mongolite::mongo(
    collection = mg_config$collection,
    url = with(mg_config,
               # mongodb://username:password@host:port
               sprintf("mongodb://%s:%s@%s:%d/", username, password, host, as.numeric(port))),
    db = mg_config$database
  )

  # return connection
  return(c)

}



# Create Common Script from Template -------------------------------------------

#' Initiate Commonly Used Script
#'
#' @description Initiate commonly used script:
#'
#' \code{init_config} - To declare database and API configuration
#'
#' \code{init_plumber} - To convert R code to web API
#'
#' Please modify content accordingly.
#'
#' @param name script selection
#' @param path Path to generate template. Default being the current directory.
#' @param overwrite Overwrite? Default = FALSE
#'
#' @return
#' Boolean - True if success, False if failure
#'
#' @export
#' @rdname init_script
init_script <- function(name, path = ".", overwrite = FALSE) {

  # clean up '/' in path if any
  path <- gsub(pattern = "\\/", replacement = "", x = path)

  # check if path exists
  if(!dir.exists(path)) {
    stop("Path not found.")
  }

  # declare R type
  f <- paste0(name, ".R")

  # read from template
  template <- readLines(system.file("template", f, package = "dkbi"))

  # path + file
  p <- paste0(path, "/", f)

  # not overwrite if file exists in path and overwrite is set to FALSE
  if(file.exists(p) & !overwrite) {
    message(sprintf("File exists in %s. Not proceeding.", path))
    return(FALSE)
  }

  # export
  write(template, p)

  # return boolean
  file.exists(p)

}

#' @export
#' @rdname init_script
init_config <- function(path = ".", overwrite = FALSE) {
  init_script("config", path, overwrite)
}

#' @export
#' @rdname init_script
init_plumber <- function(path = ".", overwrite = FALSE) {
  init_script("plumber", path, overwrite)
}
