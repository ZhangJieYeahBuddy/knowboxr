
<!-- README.md is generated from README.Rmd. Please edit that file -->

[![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)

# knowboxr

A general purpose package for Knowbox data analytics. It mainly helps to
fetch credentials from online key-value store and establish database
connection. You must have `consul` with host, port, and swagger
specified in your `R` global environment.

这是作业盒子数据分析团队的 R 功能包，主要用来连接线上的 key-value 存储以及数据库。同时，也支持从 R 环境里启动 `SSH`
反向代理以及下载云端列表。你必须在 R 的全局环境里创建命名 `consul` 的对象，带有连接地址、端口、后缀。

## Installation

For stable release,

``` r
devtools::install_github("tmasjc/knowboxr")
```

For development version,

``` r
devtools::install_github("tmasjc/knowboxr", ref = "development")
```

To build from source,

``` bash
# On Terminal, not R
wget -O knowboxr.tar.gz https://github.com/tmasjc/knowboxr/archive/v0.1.X.tar.gz
R CMD INSTALL knowboxr.tar.gz
```

## Declare Consul Environment in `R`

Replace host and port with true value.

``` r
# consul environment
consul <- new.env()
consul$host <- "some host"
```

It is recommended to preset above variables via `.Renviron`.

``` r
consul <- new.env()
consul$host <- Sys.getenv("consul.host")
consul$port <- Sys.getenv("consul.port")
consul$swagger <- Sys.getenv("consul.swagger")
```

## Required Parameters From Consul

For all functions that require to retrieve key-value from Consul, use
`get_params()` to obtain information.

``` r
# to download sheet from online API
knowboxr::get_params(download_sheet)
```

    ## [1] "username" "password"

``` r
# to connect to MySQL database
knowboxr::get_params(est_mysql_conn)
```

    ## [1] "username" "password" "host"     "port"     "database"

## Establish Reverse Proxy

``` r
# do one time only
register_params(id = "some_tunnel", key = get_params(reverse_proxy))

# return a R6 object
p <- reverse_proxy("some_tunnel")
# check status
p$is_alive()
# kill process
p$kill()
```

Note: `reverse_proxy` uses `ProcessX` package underneath.

## Establish Connection to Database

``` r
# do one-time only
# assume some postgres database
register_params(id = "some_postgres_database", key = get_params(est_pgres_conn))

# we can now establish connection by calling registered id
conn <- est_pgres_conn("some_postgres_database")
o_tbl <- tbl(conn, "some_table")
```

Currently supported databases and required drivers:

1.  `MySQL`
2.  `PostgreSQL`
3.  `Mongo`

For full list see `ls(name = "package:knowboxr", pattern = "est_*")`.

## Collect Data from Database in Chunks

Imagine we have to collect data ranged from year 2018 to year 2019. We
specify the time-dependent variable and `col_chunks` automatically
breaks down the data collection by chunks (default is `weeks`).

``` r
# after establish connection to database from above
o_tbl %>% 
  select(var1, var2) %>% 
  col_chunks(timevar = time, min = "2018-01-01", max = "2019-01-01")
```

## Download Spreadsheet From Online API

Currently supports: [Sheetlabs](%22https://sheetlabs.com/%22)

``` r
download_sheet("ORG/ABC")
```

## Dataset

1.  `county_level` - Counties’ information table
2.  `city_geocode` - Cities’ longitude and latitude table

-----

Please note that this project is released with a [Contributor Code of
Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree
to abide by its terms.
