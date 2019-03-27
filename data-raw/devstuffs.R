library(devtools)
library(usethis)
library(desc)

# Remove default DESC
unlink("DESCRIPTION")
# Create and clean desc
my_desc <- description$new("!new")

# Set your package name
my_desc$set("Package", "knowboxr")

#Set your name
my_desc$set("Authors@R", "person('Thomas', 'Jc',
            email = 'tangms@knowbox.cn',
            role = c('cre', 'aut'))")

# Remove some author fields
my_desc$del("Maintainer")

# Set the version
my_desc$set_version("0.1.0")

# The title of your package
my_desc$set(Title = "knowboxr")
# The description of your package
my_desc$set(Description = "A general purpose package for Knowbox data analytics.")
# The urls
my_desc$set("URL", "https://github.com/tmasjc/knowboxr.git")
my_desc$set("BugReports", "https://github.com/tmasjc/dkbi/issues")
# Use lazy data
my_desc$set("LazyData", "true")
# Save everyting
my_desc$write(file = "DESCRIPTION")

# If you want to use the MIT licence, code of conduct, and lifecycle badge
use_mit_license(name = "Thomas Jc")
use_code_of_conduct()
use_lifecycle_badge("Experimental")
use_news_md()

# Get the dependencies
use_package("rlang")
use_package("processx")
use_package("DBI")
use_package("dplyr")
use_package("httr")
use_package("jsonlite")
use_package("curl")
use_package("attempt")
use_package("magrittr")
use_package("base64enc")
use_package("purrr")
use_package("mongolite")
use_package("RMariaDB")
use_package("RPostgreSQL")

# Clean your description
use_tidy_description()
