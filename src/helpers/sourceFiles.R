sourceFilesForActivityLevelOptimization <- function() {
  source('src/helpers/ObjectiveFunctionHelper2.R')
  source("src/optimization/RequiredFunctions2.R")
  source("src/constraints/MarketInstrumentActivityConstraint.R")
}

sourceFilesForMarketInstrumentLevelOptimization <- function() {
  source('src/helpers/ObjectiveFunctionHelper.R')
  source("src/optimization/RequiredFunctions.R")
  source("src/constraints/MarketInstrumentConstraint.R")
}

commonSourceFiles <- function() {
  source("src/optimization/OptimizeHelper.R")
  source('src/helpers/CommonObjectiveFunctionHelper.R')
  source("src/helpers/DataPreparation.R")
  source("src/optimization/CommonRequiredFunctions.R")
  source("src/optimization/Optimize.R")
  source("src/optimization/FinalCallv2.R")
  source('src/optimization/Optimizer.R')
  source("src/optimization/Initialization.R")
  source("src/optimize/OptimizationRunner.R")
  source("src/constraints/BaseConstraint.R")
}