rm(list=ls(all=TRUE))

library(jsonlite)
library(logging)

source('Routes.R')

config <<- fromJSON("./config.json")

port <- as.numeric(config["port"])
ipAddress <- config[["address"]]
logger_prefix = "bcg.mc.optimization"

arguments <- commandArgs(TRUE)

if (length(arguments) > 0) {
  port = arguments[1]
}

startServer <- function (ipAddress, port) {
  status <- -1

  if (as.integer(R.version[["svn rev"]]) > 59600) {
    status <- .Call(tools:::startHTTPD, ipAddress, port)
  } else {
    status <- .Internal(startHTTPD(ipAddress, port))
  }

  if (status == 0) {
    unlockBinding("httpdPort", environment(tools:::startDynamicHelp))
    assign("httpdPort", port, environment(tools:::startDynamicHelp))

    server <- Rhttpd$new()
    server$listenAddr <- ipAddress
    server$listenPort <- port

    Routes()$register(server)

     while (TRUE) Sys.sleep(1000)
  }
}

basicConfig()
setLevel(config["log_level"][[1]])

log_file <- paste0(config["log_directory"][[1]], "/", config["log_file_name"][[1]])

addHandler(writeToFile, logger = logger_prefix, file=log_file)

startServer(ipAddress, port)
