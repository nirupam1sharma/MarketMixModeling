library(testthat)
library(data.table)


context("FinalCallDataPrep")
source("src/helpers/sourceFiles.R")
library(jsonlite)
config <<- fromJSON("./config.json")


test_that("data prep with multiple markets in portfolio", {
    commonSourceFiles()
    sourceFilesForMarketInstrumentLevelOptimization()
  # with portfolio constraints
    AllMeasure <- read.csv("tests/testData/withMultipleMarkets/AllMeasure.csv")
    PortfolioConstraint <- read.csv("tests/testData/withMultipleMarkets/PortfolioConstraint.csv")
    MarketConstraint <- read.csv("tests/testData/withMultipleMarkets/MarketConstraint.csv")
    MarketInstrumentConstraintDt <- read.csv("tests/testData/withMultipleMarkets/MarketInstrumentConstraints.csv")
    setDT(AllMeasure)
    setDT(PortfolioConstraint)
    setDT(MarketConstraint)
    setDT(MarketInstrumentConstraintDt)
    
    Constraint <- MarketInstrumentConstraint$new()
    Constraint$LowerLimit <- 1
    Constraint$UpperLimit <- 50
    
    Constraint$init(AllMeasure, PortfolioConstraint, MarketConstraint, MarketInstrumentConstraintDt, 1, 1)
    
    
    AllMeasureOutput <- read.csv("tests/testData/withMultipleMarkets/AllMeasureOutput.csv")
    ub <- read.csv("tests/testData/withMultipleMarkets/ub.csv")
    lb <- read.csv("tests/testData/withMultipleMarkets/lb.csv")
    limit <- read.csv("tests/testData/withMultipleMarkets/limit.csv")
    startingValue <- read.csv("tests/testData/withMultipleMarkets/startingValue.csv")
    PortfolioLevelROI <- read.csv("tests/testData/withMultipleMarkets/PortfolioLevelROI.csv")
    MarketInscopeAndROI <- read.csv("tests/testData/withMultipleMarkets/MarketDetails.csv")
    Min_InscopeBudget <- read.csv("tests/testData/withMultipleMarkets/MinInscope.csv")
    Max_InscopeBudget <- read.csv("tests/testData/withMultipleMarkets/MaxInscope.csv")
    SourceFactorsWithDropScopeConstraint <- read.csv("tests/testData/withMultipleMarkets/SourceFactorsWithDropScopeConstraint.csv")
    
    all(Constraint$getUb() == ub)
    all(Constraint$getlb() == lb)
    all(Constraint$getLimit() == limit)
    all(Constraint$getStartingValue() == startingValue)
    #all(result$MarketInscopeAndROI == MarketInscopeAndROI)
    all(Constraint$Min_InscopeBudget == Min_InscopeBudget)
    all(Constraint$Max_InscopeBudget == Max_InscopeBudget)
    #all(result$SourceFactorsWithDropScopeConstraint == SourceFactorsWithDropScopeConstraint)
    #all(result$AllMeasure == AllMeasureOutput)
    all(Constraint$PortfolioLevelROI == PortfolioLevelROI)
})

test_that("data prep with one market in portfolio with portfolio constraints", {
  commonSourceFiles()
  sourceFilesForMarketInstrumentLevelOptimization()
  # with portfolio constraints
  AllMeasure <- read.csv("tests/testData/withSingleMarketWithPortfolioConstraints/AllMeasure.csv")
  PortfolioConstraint <- read.csv("tests/testData/withSingleMarketWithPortfolioConstraints/PortfolioConstraint.csv")
  MarketConstraint <- read.csv("tests/testData/withSingleMarketWithPortfolioConstraints/MarketConstraint.csv")
  MarketInstrumentConstraintDt <- read.csv("tests/testData/withSingleMarketWithPortfolioConstraints/MarketInstrumentConstraints.csv")
  setDT(AllMeasure)
  setDT(PortfolioConstraint)
  setDT(MarketConstraint)
  setDT(MarketInstrumentConstraintDt)
  
  Constraint <- MarketInstrumentConstraint$new()
  Constraint$LowerLimit <- 1
  Constraint$UpperLimit <- 50
  Constraint$init(AllMeasure, PortfolioConstraint, MarketConstraint, MarketInstrumentConstraintDt, 1, 1)
  
  
  AllMeasureOutput <- read.csv("tests/testData/withSingleMarketWithPortfolioConstraints/AllMeasureOutput.csv")
  ub <- read.csv("tests/testData/withSingleMarketWithPortfolioConstraints/ub.csv")
  lb <- read.csv("tests/testData/withSingleMarketWithPortfolioConstraints/lb.csv")
  limit <- read.csv("tests/testData/withSingleMarketWithPortfolioConstraints/limit.csv")
  startingValue <- read.csv("tests/testData/withSingleMarketWithPortfolioConstraints/startingValue.csv")
  PortfolioLevelROI <- read.csv("tests/testData/withSingleMarketWithPortfolioConstraints/PortfolioLevelROI.csv")
  MarketInscopeAndROI <- read.csv("tests/testData/withSingleMarketWithPortfolioConstraints/MarketDetails.csv")
  Min_InscopeBudget <- read.csv("tests/testData/withSingleMarketWithPortfolioConstraints/MinInscope.csv")
  Max_InscopeBudget <- read.csv("tests/testData/withSingleMarketWithPortfolioConstraints/MaxInscope.csv")
  SourceFactorsWithDropScopeConstraint <- read.csv("tests/testData/withSingleMarketWithPortfolioConstraints/SourceFactorsWithDropScopeConstraint.csv")
  
  all(Constraint$getUb() == ub)
  all(Constraint$getlb() == lb)
  all(Constraint$getLimit() == limit)
  all(Constraint$getStartingValue() == startingValue)
  #all(result$MarketInscopeAndROI == MarketInscopeAndROI)
  all(Constraint$Min_InscopeBudget == Min_InscopeBudget)
  all(Constraint$Max_InscopeBudget == Max_InscopeBudget)
  #all(result$SourceFactorsWithDropScopeConstraint == SourceFactorsWithDropScopeConstraint)
  #all(result$AllMeasure == AllMeasureOutput)
  all(Constraint$PortfolioLevelROI == PortfolioLevelROI)
})

test_that("data prep with one market in portfolio with market constraints", {
  commonSourceFiles()
  sourceFilesForMarketInstrumentLevelOptimization()
  # with portfolio constraints
  AllMeasure <- read.csv("tests/testData/withSingleMarketWithMarketConstraints/AllMeasure.csv")
  PortfolioConstraint <- read.csv("tests/testData/withSingleMarketWithMarketConstraints/PortfolioConstraint.csv")
  MarketConstraint <- read.csv("tests/testData/withSingleMarketWithMarketConstraints/MarketConstraint.csv")
  MarketInstrumentConstraintDt <- read.csv("tests/testData/withSingleMarketWithMarketConstraints/MarketInstrumentConstraints.csv")
  setDT(AllMeasure)
  setDT(PortfolioConstraint)
  setDT(MarketConstraint)
  setDT(MarketInstrumentConstraintDt)
  
  Constraint <- MarketInstrumentConstraint$new()
  Constraint$LowerLimit <- 1
  Constraint$UpperLimit <- 50

  Constraint$init(AllMeasure, PortfolioConstraint, MarketConstraint, MarketInstrumentConstraintDt, 1, 1)
  
  AllMeasureOutput <- read.csv("tests/testData/withSingleMarketWithMarketConstraints/AllMeasureOutput.csv")
  ub <- read.csv("tests/testData/withSingleMarketWithMarketConstraints/ub.csv")
  lb <- read.csv("tests/testData/withSingleMarketWithMarketConstraints/lb.csv")
  limit <- read.csv("tests/testData/withSingleMarketWithMarketConstraints/limit.csv")
  startingValue <- read.csv("tests/testData/withSingleMarketWithMarketConstraints/startingValue.csv")
  PortfolioLevelROI <- read.csv("tests/testData/withSingleMarketWithMarketConstraints/PortfolioLevelROI.csv")
  MarketInscopeAndROI <- read.csv("tests/testData/withSingleMarketWithMarketConstraints/MarketDetails.csv")
  Min_InscopeBudget <- read.csv("tests/testData/withSingleMarketWithMarketConstraints/MinInscope.csv")
  Max_InscopeBudget <- read.csv("tests/testData/withSingleMarketWithMarketConstraints/MaxInscope.csv")
  SourceFactorsWithDropScopeConstraint <- read.csv("tests/testData/withSingleMarketWithMarketConstraints/SourceFactorsWithDropScopeConstraint.csv")
  
  all(Constraint$getUb() == ub)
  all(Constraint$getlb() == lb)
  all(Constraint$getLimit() == limit)
  all(Constraint$getStartingValue() == startingValue)
  #all(result$MarketInscopeAndROI == MarketInscopeAndROI)
  all(Constraint$Min_InscopeBudget == Min_InscopeBudget)
  all(Constraint$Max_InscopeBudget == Max_InscopeBudget)
  #all(result$SourceFactorsWithDropScopeConstraint == SourceFactorsWithDropScopeConstraint)
  #all(result$AllMeasure == AllMeasureOutput)
  all(Constraint$PortfolioLevelROI == PortfolioLevelROI)
})

