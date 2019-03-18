
<!-- README.md is generated from README.Rmd. Please edit that file -->

[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)

# knowboxr

A general purpose package for Knowbox data analytics.

## Installation

``` r
devtools::install_github("tmasjc/knowboxr")
```

## Preset `Consul` Environment in `R`

Replace host and port with true value.

``` r
# consul environment
consul <- new.env()
consul$host <- "some host"
```

It is recommended to set above variables via `.Renviron`.

``` r
consul <- new.env()
consul$host <- Sys.getenv("consul.host")
consul$port <- Sys.getenv("consul.port")
consul$swagger <- Sys.getenv("consul.swagger")
```

## Common Workflow

Establish connection to database

``` r
conn <- est_pgres_conn('some database')
tbl(conn, "some table")
DBI::dbDisconnect(conn)
```

Driver for databases:

1.  `MySQL` - [RMariaDB](https://github.com/r-dbi/RMariaDB)
2.  `PostgreSQL` - [RPostgreSQL](https://github.com/r-dbi/RPostgres)
3.  `Mongo` - [mongolite](https://github.com/jeroen/mongolite/)

-----

Please note that this project is released with a [Contributor Code of
Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree
to abide by its terms.
