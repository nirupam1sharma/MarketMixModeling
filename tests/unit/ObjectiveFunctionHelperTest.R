library(testthat)
library(jsonlite)
library(data.table)

source("src/helpers/CommonObjectiveFunctionHelper.R")

context("Objective Function Helper")

test_that("get optimized tertiary kpi when secondary kpi is only composed of primary kpi", {
  PressureUnit <-4
  PressureUnitAdStockRatio<-5
  Carryover <- 6
  Lag <- 7
  Rows <- 1
  SecKPIValues <- 1

  allData <- data.table(Base=1, ModelKPI=2, AttributedInvestment=3, PressureUnit=PressureUnit, PressureUnitAdStockRatio=PressureUnitAdStockRatio,
                        Carryover=Carryover, Lag=Lag, Key='1:2:3')
  attributedImpacts <- matrix(50)
  expectedOutput <- data.table(Base=1, ModelKPI=2, AttributedInvestment=3, PressureUnit=PressureUnit, PressureUnitAdStockRatio=PressureUnitAdStockRatio,
                                Carryover=Carryover, Lag=Lag, Key='1:2:3', AttributedImpact=50, TertiaryKPI=47)

  KPIFormula <- data.table(market_id = 1, kpi_id= 2, kpi_type='Tertiary Kpi', formula="-AttributedInvestment")
  with_mock(
    `AttributedImpactCalculation` = function(PressureUnit, PressureUnitAdStockRatio, Carryover, Lag, Rows, SecKPIValues) attributedImpacts,
    output <- GetOptimisedTertiaryKpi(KPIFormula, allData)
  )
  expect_true(all.equal(output, expectedOutput, check.attributes=FALSE))
})

test_that("get optimized secondary kpi when optimizing secondary kpi", {
  PressureUnit <-c(4, 4)
  PressureUnitAdStockRatio<-c(5, 5)
  Carryover <- c(6, 6)
  Lag <- c(7, 7)
  Rows <- 2
  
  allData <- data.table(ReceivingMarketId=c(1,2), Futt_Eff=c(0, 20), Base=c(10, 0), ModelKPI=c(2, 2), AttributedInvestment=c(3, 3), PressureUnit=PressureUnit, 
                        PressureUnitAdStockRatio=PressureUnitAdStockRatio, Carryover=Carryover, Lag=Lag, Key=c('1:2:3', '2:2:3'))
  attributedImpacts1 <- matrix(50)
  attributedImpacts2 <- matrix(60)
  # expectedOutput <- data.table(Base=10, ModelKPI=2, AttributedInvestment=3, PressureUnit=PressureUnit, PressureUnitAdStockRatio=PressureUnitAdStockRatio,
  #                               Carryover=Carryover, Lag=Lag, Key='1:2:3', AttributedImpact=50, TertiaryKPI=47)
  expectedOutput <- data.table(ReceivingMarketId=c(1,2), Futt_Eff=c(0, 20), Base=c(10, 0), ModelKPI=c(2, 2), AttributedInvestment=c(3, 3), PressureUnit=PressureUnit, 
                               PressureUnitAdStockRatio=PressureUnitAdStockRatio, Carryover=Carryover, Lag=Lag, Key=c('1:2:3', '2:2:3'), AttributedImpact=c(50, 60), TertiaryKPI=c(50, 60))
  KPIFormula <- data.table(market_id = c(1, 2), kpi_id= c(2, 2), kpi_type=c('Secondary Kpi', 'Secondary Kpi'), formula=c("Base", "Futt_Eff"))
  with_mock(
    `AttributedImpactCalculation` = function(PressureUnitArg, PressureUnitAdStockRatioArg, CarryoverArg, LagArg, RowsArg, SecKPIValuesArg) {
      if(SecKPIValuesArg == 20) {
        return(attributedImpacts2)
      } else {
        return(attributedImpacts1)
      }
    },
    output <- GetOptimisedTertiaryKpi(KPIFormula, allData)
  )
  expect_true(all.equal(output, expectedOutput, check.attributes=FALSE))
})

test_that("get optimized tertiary kpi when secondary kpi is composed of primary kpi and other kpi variables", {
  PressureUnit <-c(4, 4)
  PressureUnitAdStockRatio<-c(5, 5)
  Carryover <- c(6, 6)
  Lag <- c(7, 7)
  Rows <- 2

  allData <- data.table(ReceivingMarketId=c(1,2), Futt_Eff=c(0, 20), Base=c(10, 0), ModelKPI=c(2, 2), AttributedInvestment=c(3, 3), PressureUnit=PressureUnit,
                        PressureUnitAdStockRatio=PressureUnitAdStockRatio, Carryover=Carryover, Lag=Lag, Key=c('1:2:3', '2:2:3'))
  attributedImpacts1 <- matrix(50)
  attributedImpacts2 <- matrix(60)
  # expectedOutput <- data.table(Base=10, ModelKPI=2, AttributedInvestment=3, PressureUnit=PressureUnit, PressureUnitAdStockRatio=PressureUnitAdStockRatio,
  #                               Carryover=Carryover, Lag=Lag, Key='1:2:3', AttributedImpact=50, TertiaryKPI=47)
  expectedOutput <- data.table(ReceivingMarketId=c(1,2), Futt_Eff=c(0, 20), Base=c(10, 0), ModelKPI=c(2, 2), AttributedInvestment=c(3, 3), PressureUnit=PressureUnit,
                               PressureUnitAdStockRatio=PressureUnitAdStockRatio, Carryover=Carryover, Lag=Lag, Key=c('1:2:3', '2:2:3'), AttributedImpact=c(50, 60), TertiaryKPI=c(47, 57))
  KPIFormula <- data.table(market_id = c(1, 2), kpi_id= c(2, 2), kpi_type=c('Tertiary Kpi', 'Tertiary Kpi'), formula=c("Base-AttributedInvestment", "Futt_Eff-AttributedInvestment"))
  with_mock(
    `AttributedImpactCalculation` = function(PressureUnitArg, PressureUnitAdStockRatioArg, CarryoverArg, LagArg, RowsArg, SecKPIValuesArg) {
      if(SecKPIValuesArg == 20) {
        return(attributedImpacts2)
      } else {
        return(attributedImpacts1)
      }
    },
    output <- GetOptimisedTertiaryKpi(KPIFormula, allData)
  )
  expect_true(all.equal(output, expectedOutput, check.attributes=FALSE))
})

test_that("get optimized spend and pressure unit calculates new pressure unit and adstock to be used in next generation based on weighths given by Genoud", {
})