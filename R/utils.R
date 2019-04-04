# Parameters for Functions ------------------------------------------------

#' Required Consul Parameters (Keys) for Various Functions
#'
#' @description
#' Parameters or keys needed for functions to establish connections.
#' @param func Function to make connection (e.g \code{est_mysql_conn})
#'
#' @return
#' Vector. Parameters for function requested.
#' NULL if function does not require to retrieve key from Consul.
#'
#' @export
#'
#' @examples
#' \dontrun{
#'
#' # see some examples
#' ls(name = "package:knowboxr", pattern = "est")
#' get_params(est_mongo_conn)
#' }
get_params <- function(func) {

  # quoting unevaluated expression
  ind <- as.character(substitute(func))

  # if not found in list
  if (!ind %in% names(func_list)) {
    return(NULL)
  }

  # return parameters
  func_list[[ind]]
}

# Write to Consul ---------------------------------------------------------

#' Register Key
#'
#' @importFrom httr PUT
#' @keywords internal
register_key <- function(url, postfix) {

  # do not proceed if key exists
  if (!is.na(get_kv(postfix))) {
    message(sprintf("Did not proceed to register %s. Key exists.", postfix))
    return(FALSE)
  }

  # put key into consul with default value
  res <- httr::PUT(url, body = "{default}")

  # report status
  ifelse(res$status_code == 200, TRUE, FALSE)

}

#' Register Parameters on Consul
#'
#' @description
#' Register keys with dummy values into Consul KV store.
#'
#' See https://www.consul.io/ for more about Consul.
#'
#' @param id Consul identifier
#' @param key Key to register
#'
#' @return Logical. TRUE indicates success. FALSE indicated failure.
#' @importFrom purrr map2
#' @examples
#' \dontrun{
#' register_params("some_api", "endpoint")
#'
#' # See ?get_params
#' register_params("some_mysql_database", get_params(est_mysql_conn))
#' }
#' @export
register_params <- function(id, key) {

  # required parameters
  params <- c("host", "port", "swagger")

  # defensive
  if (!all(params %in% ls(envir = consul))) {
    stop("One or more Consul parameters cannot be found.")
  }

  # find Consul
  url <- with(consul, sprintf("http://%s:%s/%s", host, port, swagger))

  # where and what to put
  postfix <- paste(id, key, sep = "/")
  url <- paste(url, postfix, sep = "/")

  # do register
  res <- purrr::map2(.x = url, .y = postfix, register_key)
  names(res) <- postfix

  return(res)
}


# Read from Consul --------------------------------------------------------

#' Obtain Key / Value from Consul
#'
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
  res <- httr::GET(url) %>% httr::content()

  # if return empty
  if (!length(res) > 0) {
    return(NULL)
  }

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



# Reverse Proxy -----------------------------------------------------------

#' Do Reverse Proxy
#'
#' Create a reverse proxy as a background process. Concept explained in details see here
#' https://unix.stackexchange.com/questions/46235/how-does-reverse-ssh-tunneling-work.
#'
#' @param conn Proxy name (key) to fetch from \code{Consul}.
#' @description Establish a reverse proxy connection.
#'
#' @return An R6 object generated from \code{Processx}
#' @importFrom processx process
#' @export
reverse_proxy <- function(conn) {

  # fetch credentials
  ssh <- get_batch_kv(conn, get_params(reverse_proxy))

  # ssh -L sourcePort:forwardToHost:onPort connectToHost
  p <- with(ssh, processx::process$new("ssh",
                                       c(
                                         "-L", sprintf("%s:%s:%s", port, farawayhost, farawayport),
                                         "-p", remoteport,
                                         sprintf("%s@%s", username, remotehost),
                                         "-NnT"
                                       )))
  # return R6 object
  return(p)
}

# Establish Connection to Common Database ---------------------------------

#' Establish Connection to Common Databases
#'
#' @name est_some_conn
#' @description Fetch credentials from Consul K/V store and establish connection to database.
#'
#' In order for this function to work, one will first need to register parameters in Consul.
#' See \code{?register_params}
#'
#' @param db Database to connect to
#' @param drv Database driver
#' @param params See \code{?get_params}
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
est_some_conn <- function(db, drv, params) {

  # fetch credentials
  db_config <- get_batch_kv(db, params)

  # check if all required params are specified
  if(!all(params %in% names(db_config))){
    stop("One or more MySQL parameters is missing")
  }

  #
  message("")

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
est_mysql_conn <- function(db, drv = RMariaDB::MariaDB()) {
  est_some_conn(db, drv, params = get_params(est_mysql_conn))
}

#' @importFrom RPostgreSQL PostgreSQL
#' @export
#' @rdname est_some_conn
est_pgres_conn <- function(db, drv = RPostgreSQL::PostgreSQL()) {
  est_some_conn(db, drv, params = get_params(est_pgres_conn))
}


#' @importFrom mongolite mongo
#' @export
#' @rdname est_some_conn
est_mongo_conn <- function(db) {

  # fetch mongo credentials
  mg_config <- get_batch_kv(db, get_params(est_mongo_conn))

  # check if the credentials are specified
  if(!all(get_params(est_mongo_conn) %in% names(mg_config))){
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



# Collect Data in Chunks --------------------------------------------------

#' Break Down 2 Dates In Interval
#' @keywords internal
cut_dates <- function(start_date, end_date, cut) {

  # break down by months, weeks or days
  cuts <- seq(as.Date(start_date), as.Date(end_date), by = cut)

  # return cut intervals in pair
  return(list(
    x = cuts[1:(length(cuts) - 1)],
    y = cuts[2:length(cuts)]
  ))

}

#' Execute Single Query
#' @importFrom magrittr %>%
#' @importFrom rlang enquo quo_text
#' @importFrom dplyr filter collapse
#' @keywords internal
exec_query <- function(query, timevar, from, to, collect) {

  # which time variable to filter from
  var = rlang::enquo(timevar)

  ## use quo_text to coerse type 'closure' to character
  message(sprintf("<< -- Ready to collect data from {%s} %s to %s -- >>", rlang::quo_text(var), from, to))

  # execute query and collect data
  q = query %>% filter(!!var >= from, !!var < to)

  # do not force computation unless it is neccessary
  if(collect) {
    collect(q)
  } else {
    collapse(q)
  }

}

#' Collect Data in Chunks
#'
#' @param query SQL query to fetch from database.
#' @param timevar Time-dependent variable to be splitted.
#' @param min Mininum or start date.
#' @param max Maximum or end date.
#' @param break_by A character string, containing one of "day", "week", "month", "quarter" or "year".
#' @param collect If true, retrieves data into a local tibble.
#' @return Data in chunks in list form.
#'
#' @importFrom magrittr %>%
#' @importFrom purrr map2
#' @importFrom rlang enquo
#'
#' @examples
#' \dontrun{
#' src <- tbl(conn, "some_table")
#' src %>% col_chunks(register_time, "2019-01-01", "2019-12-31")
#' }
#' @export
col_chunks <- function(query, timevar, min, max, break_by = "weeks", collect = FALSE) {

  # must first capture before proceed to check
  # see https://stackoverflow.com/questions/46309408/using-dplyr-enquo-after-calling-argument
  var = rlang::enquo(timevar)

  # capture string if not a closure
  if (typeof(timevar) == "character") {
    var = rlang::sym(timevar)
  }

  # break down in chunks
  d <- cut_dates(min, max, break_by)

  # return
  map2(.x = d$x, .y = d$y, .f = ~ exec_query(query, !!var, .x, .y, collect = collect))

}



# Collect Data from Source ---------------------------------------------


#' Fetch Sheet from Source
#'
#' Fetch sheet from online API. Currently only supports Sheetlabs.
#' For more info visit https://sheetlabs.com/
#'
#' @param sheet API to fetch from Sheetlabs
#' @param source Key to fetch from \code{Consul} to obtain credentials. Default is 'Sheetlabs'.
#' @return A data frame if successful. A list of error message and code if failure
#' @importFrom httr GET authenticate content
#' @importFrom jsonlite fromJSON
#' @export
download_sheet <- function(sheet, source = "sheetlabs") {

  # destination
  url = paste0("https://sheetlabs.com/", sheet)

  # get username and token from Consul
  auth <- get_batch_kv(source, get_params(download_sheet))

  # fetch data
  message(sprintf("Ready to download data from %s", url))
  res <- httr::GET(url, httr::authenticate(auth$username, auth$password))

  # defensive
  if (res$status_code != 200) {
    return(list(errormsg = "Failed to download",
                errorcode = res$status_code))
  }

  # extract content to data frame
  jsonlite::fromJSON(httr::content(res, as = "text"))

}

# Dataset -----------------------------------------------------------------

#' Living Quality Index of Various Counties.
#'
#' An in-house dataset containing various counties' information.
#'
#' @format A tibble with 3240 rows and 8 variables:
#' \describe{
#'  \item{province_id}{省份 ID}
#'  \item{province_name}{省份}
#'  \item{city_id}{城市 ID}
#'  \item{city_name}{城市}
#'  \item{county_id}{县级 ID}
#'  \item{county_name}{县级}
#'  \item{county_level}{县级等级，A 为最好，E 为最差}
#'  \item{update_date}{最后更新日期}
#' }
#' @source Anjuke 安居客 2017
"county_level"


#' Geocodes of Various Cities.
#'
#' A general dataset containing various cities' longitude and latitude information.
#'
#' @format A tibble with 334 rows and 3 variables.
#' \describe{
#'  \item{city_name}{Name of city}
#'  \item{lon}{Longitude}
#'  \item{lat}{Latitude}
#' }
#' @source Amap 高德地图 2019
"city_geocode"
