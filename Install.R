isInstalled <- function(package)
{
  return(require(package, character.only = TRUE))
}

install <- function(package) {
  print(paste0("Installing ", package))
  libName <- list.files(path="lib/", pattern = package, recursive = TRUE)
  install.packages(paste0("lib/",libName), repos = NULL, type = "source", dep = TRUE)
  if (!require(package, character.only = TRUE)) stop("Package not found")
  print(paste0("Done ",package))
}

installDependencies <- function() {
  print("Installing Dependencies")
  libName <- list.files(path="lib/dependencies/", pattern = NULL, recursive = TRUE)
  install.packages(paste0("lib/dependencies/",libName), repos = NULL, type = "source")
  print("Done Installing Dependencies")
}

neededPackages <-
  c(
    "Rook",
    "jsonlite",
    "dplyr",
    "tidyjson",
    "snow",
    "data.table",
    "rgenoud",
    "DataCombine",
    "reshape",
    "RPostgreSQL",
    "parallel",
    "testthat",
    "logging"
  )

check <- function() {
  installDependencies()
  for (key in neededPackages) {
    if (!isInstalled(key)) {
      install(key)
    }
  }
}

check()
