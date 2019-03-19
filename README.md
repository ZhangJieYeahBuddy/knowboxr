
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

## Establish Reverse Proxy

``` r
# returned as a R6 object
p <- reverse_proxy("some tunnel")
# check status
p$is_alive()
# kill process
p$kill()
```

See `?reverse_proxy` for required config.

Note: `reverse_proxy` uses `ProcessX` package underneath.

## Establish Connection to Database

``` r
# assume some postgres database
conn <- est_pgres_conn('some database')
o_tbl <- tbl(conn, "some table")
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

## Dataset

1.  `county_level` - Counties’ information table
2.  `city_geocode` - Cities’ longitude and latitude table

-----

Please note that this project is released with a [Contributor Code of
Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree
to abide by its terms.
