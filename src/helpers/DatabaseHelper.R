connectToDatabase <- function(config) {
 drv <- dbDriver("PostgreSQL")
 con <- connectToDatabaseWith(config["dbName"], config["host"], config["dbPort"], config["dbUsername"], config["dbPassword"])
 return(con)
}

connectToDatabaseWith <- function(dbname, host, port, user, password) {
  drv <- dbDriver("PostgreSQL")
  
  con <- dbConnect(
    drv,
    dbname = dbname,
    host = host,
    port = as.numeric(port),
    user = user,
    password = password
  )
  
  return(con)
}

disconnectFromDatabase <- function(con) {
 dbDisconnect(con)
}                             
