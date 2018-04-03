library(jsonlite)
source("src/helpers/sourceFiles.R")
source("src/optimization/CommonRequiredFunctions.R")
source('src/helpers/DatabaseHelper.R')
source("src/optimization/OptimizeHelper.R")
config <<- fromJSON('config.json')

successStatus <- config[["success_status"]]
failureStatus <- config [["failure_status"]]

OptimizationWrapper = setRefClass('OptimizationWrapper', fields = list(), 
                                  methods = list(
                                    scenario = function(scenarioId) {
                                      message <- ""
                                      optimizationResult <- NULL
                                      status <- failureStatus
                                      payLoad <- toString(getPayload(scenarioId))
                                      paramsList <- list("startDate", "planEnd", "scenarioEnd", "currentScenario")
                                      jsonPayLoad <- fromJSON(payLoad)

                                      isValid <- validateParams(paramsList, jsonPayLoad)
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
                                           message <- "Optimization failed !"
                                           status <- failureStatus
                                        } else {
                                          message <- paste0("Successfully finished Optimization for ScenarioId: ",jsonPayLoad$currentScenario$scenarioId)
                                          optimizationResult <- toJSON(output$optimizedSpend, digits = 9)
                                          status <- successStatus
                                        }
                                      } else {
                                        message <- paste0("Invalid Params For ScenarioId: ",jsonPayLoad$currentScenario$scenarioId)
                                      }
                                      saveOptimizationResult(scenarioId, optimizationResult, message, status)
                                    }
                      ))

args <- commandArgs(TRUE)
scenarioId <- args[1]
OptimizationWrapper()$scenario(scenarioId)