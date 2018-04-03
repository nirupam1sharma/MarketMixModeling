library(jsonlite)
source("src/helpers/sourceFiles.R")
source("src/optimization/OptimizeHelper.R")
source('src/helpers/DatabaseHelper.R')

OptimizationWrapperForRook = setRefClass('OptimizationWrapperForRook', fields = list(), 
                                  methods = list(
                                    scenario= function(env) {
                                      res <- Rook::Response$new()
                                      req <- Rook::Request$new(env)
                                      payLoad <- getBody(req$params())
                                      paramsList <- list("startDate", "planEnd", "scenarioEnd", "currentScenario")
                                      jsonPayLoad <- fromJSON(payLoad)
                                      isValid <- validateReqTypeAndParams("POST", req, paramsList, jsonPayLoad)
                                      if (isValid) {
                                        optimizeAtActivity <- jsonPayLoad[['optimizeAtActivity']]
                                        optimizeAtActivity <- ifelse(is.null(optimizeAtActivity),F,as.logical(optimizeAtActivity))
                                        commonSourceFiles()
                                        if(optimizeAtActivity) {
                                          sourceFilesForActivityLevelOptimization()
                                        } else {
                                          sourceFilesForMarketInstrumentLevelOptimization()
                                        }
                                        output <- Optimize()$optimizeScenario(payLoad)

                                        optimizationError <- output$optimizationError
                                        if (optimizationError) {
                                          res$write("Optimization failed !!")
                                          res$status <- 500
                                        } else {
                                          res$header("Content-Type", "application/json")
                                          res$write(toJSON(output$optimizedSpend, digits = 9))
                                          res$write(paste0("Successfully finished Optimization for ScenarioId: ",jsonPayLoad$currentScenario$scenarioId))
                                          res$status <- 200
                                        }
                                      } else {
                                        res$write(paste0("Invalid Params For ScenarioId: ",jsonPayLoad$currentScenario$scenarioId))
                                        res$status <- 500
                                      }
                                      res$finish()
                                    }
                      ))