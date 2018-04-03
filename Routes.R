library(Rook)

source("HealthChecker.R")
source("src/optimization/OptimizationWrapperForRook.R")

Routes = setRefClass("Routes", fields = list(),
  methods = list(
   register = function(server) {
     server$add(name = "app",
                app = Rook::URLMap$new('ping' = function(env) {
                  Routes()$logRequest(env)
                  HealthChecker()$ping()
                }))
     server$add(name = "scenario",
                app = Rook::URLMap$new('optimize' = function(env) {
                  Routes()$logRequest(env)
                  OptimizationWrapperForRook()$scenario(env)
                }))
  },
  logRequest=function(env){
    req <- Rook::Request$new(env)
    print(req$params())
  }
))