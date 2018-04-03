library(testthat)
library(jsonlite)
library(dplyr)
library(tidyjson)
library(data.table)

source("src/optimization/Optimize.R")
source("src/helpers/sourceFiles.R")

context("Optimize")

makeMockRequestObj<-function(methodType,params){
  req<-list();
  req$request_method <- function(){
    methodType
  }
  req$params <-function(){
    params
  }
  return(req)
}

commonSourceFiles()

test_that("getBody should return key if value is NA", {
  sourceFilesForMarketInstrumentLevelOptimization()
  key <- "{\"currentScenario\": 12}"
  value <- NA
  jsonList <- list()
  jsonList[[key]] <- value

  output <- getBody(jsonList)
  expect_that(output, equals(key))
})

test_that("getBody should return NA if key has valid value", {
  sourceFilesForMarketInstrumentLevelOptimization()
  key <- "{\"currentScenario\": 12}"
  value <- 100
  jsonList <- list()
  jsonList[[key]] <- value

  output <- getBody(jsonList)
  expect_that(output, equals(NA))
})

test_that("convertPayLoadToDataTable should convert json to data table based on key", {
  sourceFilesForMarketInstrumentLevelOptimization()
  json <- "{\"currentScenario\":{\"scenarioId\":13,\"markets\":[{\"id\":1,\"instruments\":[{\"id\":2,\"campaigns\":[{\"id\":37,\"name\":\"campaign1\",\"activities\":[{\"activityId\":13,\"name\":\"activity1\", \"isInScope\": \"TRUE\", \"startWeek\":33,\"endWeek\":34,\"weeklySpends\":[10000.0]}]}]}]}]}}"
  expectedOutput <- as.data.table(fromJSON('{
    "scenarioId" : "13",
    "marketId" : 1,
    "instrumentId" : 2,
    "campaignId" : 37,
    "campaignName": "campaign1",
    "activityId" : 13,
    "activityName": "activity1",
    "isInScope": true,
    "weeklySpends" : 10000,
    "weekNo" : 34
    }'))
  output <- convertPayLoadToDataTable(json, "currentScenario", 1)
  expect_that(output, equals(expectedOutput))
})

test_that("convertPayLoadToDataTable should convert json to data table based on key for tail in", {
  sourceFilesForMarketInstrumentLevelOptimization()
  json <- "{\"tailinScenario\":{\"scenarioId\":13,\"markets\":[{\"id\":1,\"instruments\":[{\"id\":2,\"campaigns\":[{\"id\":37,\"name\":\"campaign1\",\"activities\":[{\"activityId\":13,\"name\":\"activity1\",\"isInScope\": \"TRUE\",\"startWeek\":33,\"endWeek\":34,\"weeklySpends\":[10000.0]}]}]}]}]}}"
  expectedOutput <- as.data.table(fromJSON('{
                                           "scenarioId" : "13",
                                           "marketId" : 1,
                                           "instrumentId" : 2,
                                           "campaignId" : 37,
                                           "campaignName": "campaign1",
                                           "activityId" : 13,
                                           "activityName": "activity1",
                                           "isInScope": true,
                                           "weeklySpends" : 10000,
                                           "weekNo" : 33
  }'))
  output <- convertPayLoadToDataTable(json, "tailinScenario", 0)
  expect_that(output, equals(expectedOutput))
  })

test_that("convertPayLoadtoDataTable should return Null if key not present",  {
  sourceFilesForMarketInstrumentLevelOptimization()
  json <- "{\"tailInScenario\":null,\"startDate\":1,\"planEnd\":52,\"scenarioEnd\":52}"
  output <- convertPayLoadToDataTable(json, "currentScenario", 1)
  expect_that(nrow(output), equals(0))
})


test_that("createPortfolioConstraints should convert json to data table", {
  sourceFilesForMarketInstrumentLevelOptimization()
  json <- "{\"currentScenario\":{\"scenarioId\":47,\"returns\":1.391664093926945E8,\"portFolioConstraints\":{\"spend\":23755.775780000004,\"minSpend\":99.0,\"maxSpend\":88.0},\"markets\":[{\"id\":810,\"returns\":1.391664093926945E8,\"marketConstraints\":{\"spend\":23755.775780000004,\"minSpend\":77.0,\"maxSpend\":1.0},\"instruments\":[{\"id\":39,\"returns\":1.391664093926945E8,\"instrumentConstraints\":{\"spend\":23755.775780000004,\"minSpend\":null,\"maxSpend\":87.0},\"campaigns\":[]}, {\"id\":33,\"returns\":2.395E8,\"instrumentConstraints\":{\"spend\":2755.775780000004,\"minSpend\":50.0,\"maxSpend\":17.0},\"campaigns\":[]}]}, {\"id\":900,\"returns\":999.888,\"marketConstraints\":{\"spend\":123.456,\"minSpend\":60.0,\"maxSpend\":90.0},\"instruments\":[{\"id\":40,\"returns\":777.88,\"instrumentConstraints\":{\"spend\":23755.775780000004,\"minSpend\":null,\"maxSpend\":87.0},\"campaigns\":[]}, {\"id\":33,\"returns\":2.395E8,\"instrumentConstraints\":{\"spend\":2755.775780000004,\"minSpend\":50000.0,\"maxSpend\":99.0},\"campaigns\":[]}]}]}}"
  expectedOutput <- as.data.table(fromJSON('{"Min" : 99.0,"Max" : 88.0,"Impact" : 1.391664093926945E8,"Spend" : 23755.775780000004}'))
  output <- createPortfolioConstraints(json)
  expect_that(output, equals(expectedOutput))
  })

test_that("createMarketConstraints should convert json to data table", {
  sourceFilesForMarketInstrumentLevelOptimization()
  json <- "{\"currentScenario\":{\"scenarioId\":47,\"returns\":99.77,\"portFolioConstraints\":{\"spend\":1233.8,\"minSpend\":99.0,\"maxSpend\":88.0},\"markets\":[{\"id\":810,\"returns\":1.391664093926945E8,\"marketConstraints\":{\"spend\":23755.775780000004,\"minSpend\":77.0,\"maxSpend\":1.0},\"instruments\":[{\"id\":39,\"returns\":1.391664093926945E8,\"instrumentConstraints\":{\"spend\":23755.775780000004,\"minSpend\":null,\"maxSpend\":87.0},\"campaigns\":[]}, {\"id\":33,\"returns\":2.395E8,\"instrumentConstraints\":{\"spend\":2755.775780000004,\"minSpend\":50.0,\"maxSpend\":17.0},\"campaigns\":[]}]}, {\"id\":900,\"returns\":999.888,\"marketConstraints\":{\"spend\":123.456,\"minSpend\":60.0,\"maxSpend\":90.0},\"instruments\":[{\"id\":40,\"returns\":777.88,\"instrumentConstraints\":{\"spend\":23755.775780000004,\"minSpend\":null,\"maxSpend\":87.0},\"campaigns\":[]}, {\"id\":33,\"returns\":2.395E8,\"instrumentConstraints\":{\"spend\":2755.775780000004,\"minSpend\":50000.0,\"maxSpend\":99.0},\"campaigns\":[]}]}]}}"
  expectedOutput <- as.data.table(fromJSON('[{"MarketId":810,"Min":77.0,"Max":1.0,"Spend":23755.775780000004,"Impact":1.391664093926945E8},{"MarketId":900,"Min":60.0,"Max":90.0,"Spend":123.456,"Impact":999.888}]'))
  output <- createMarketConstraints(json)
  expect_that(output, equals(expectedOutput))
})

test_that("createInstrumentConstraints should convert json to data table", {
  sourceFilesForMarketInstrumentLevelOptimization()
  json <- "{\"currentScenario\":{\"scenarioId\":47,\"returns\":99.77,\"portFolioConstraints\":{\"spend\":1233.8,\"minSpend\":99.0,\"maxSpend\":88.0},\"markets\":[{\"id\":810,\"returns\":1.391664093926945E8,\"marketConstraints\":{\"spend\":23755.775780000004,\"minSpend\":77.0,\"maxSpend\":1.0},\"instruments\":[{\"id\":39,\"returns\":1.391664093926945E8,\"instrumentConstraints\":{\"spend\":23755.775780000004,\"minSpend\":null,\"maxSpend\":87.123},\"campaigns\":[]}, {\"id\":33,\"returns\":2.395E8,\"instrumentConstraints\":{\"spend\":2755.775780000004,\"minSpend\":50.0,\"maxSpend\":17.0},\"campaigns\":[]}]}, {\"id\":900,\"returns\":999.888,\"marketConstraints\":{\"spend\":123.456,\"minSpend\":60.0,\"maxSpend\":90.0},\"instruments\":[{\"id\":40,\"returns\":777.88,\"instrumentConstraints\":{\"spend\":23755.775780000004,\"minSpend\":null,\"maxSpend\":87.0},\"campaigns\":[]}, {\"id\":33,\"returns\":2.395E8,\"instrumentConstraints\":{\"spend\":2755.775780000004,\"minSpend\":50000.0,\"maxSpend\":99.0},\"campaigns\":[]}]}]}}"
  expectedOutput <- as.data.table(fromJSON('[{"MarketId":810,"InstrumentId":39,"Impact":1.391664093926945E8,"Spend":23755.775780000004,"Min":"NA","Max":87.123},{"MarketId":810,"InstrumentId":33,"Impact":2.395E8,"Spend":2755.775780000004,"Min":50.0,"Max":17.0},{"MarketId":900,"InstrumentId":40,"Impact":777.88,"Spend":23755.775780000004,"Min":"NA","Max":87.0},{"MarketId":900,"InstrumentId":33,"Impact":239500000.00,"Spend":2755.775780000004,"Min":50000.0,"Max":99.0}]'))
  output <- createInstrumentConstraints(json)
  expect_that(output, equals(expectedOutput))
})

test_that("should return true when all the request params are present", {
  sourceFilesForMarketInstrumentLevelOptimization()
  key <- "{\"planStart\": 1,\"planEnd\": 2,\"scenarioEnd\": 52,\"currentScenario\": 12}"
  value <- NA
  jsonList <- list()
  jsonList[[key]] <- value

  payLoad <- getBody(jsonList)
  jsonPayLoad <- fromJSON(payLoad)
  requiredParams <- list("planStart", "planEnd", "scenarioEnd", "currentScenario")

  output <- validateParams(requiredParams, jsonPayLoad)
  expect_true(output)
})

test_that("should return false when requestParams are not present", {
  sourceFilesForMarketInstrumentLevelOptimization()
  key <- "{\"planStart\": 1,\"planEnd\": 2,\"scenarioEnd\": 52}"
  value <- NA
  jsonList <- list()
  jsonList[[key]] <- value

  payLoad <- getBody(jsonList)
  jsonPayLoad <- fromJSON(payLoad)
  requiredParams <- list("planStart", "planEnd", "scenarioEnd", "currentScenario")

  output <- validateParams(requiredParams, jsonPayLoad)
  expect_false(output)
})

test_that("should return true when request type and params match", {
  sourceFilesForMarketInstrumentLevelOptimization()
  key <- "{\"planStart\": 1,\"planEnd\": 2,\"scenarioEnd\": 52,\"currentScenario\": 12}"
  value <- NA
  jsonList <- list()
  jsonList[[key]] <- value

  payLoad <- getBody(jsonList)
  jsonPayLoad <- fromJSON(payLoad)
  requiredParams <- list("planStart", "planEnd", "scenarioEnd", "currentScenario")

  req <- makeMockRequestObj("POST", requiredParams)

  output <- validateReqTypeAndParams("POST", req, requiredParams, jsonPayLoad)
  expect_true(output)
})

test_that("should return false when request type does not match", {
  sourceFilesForMarketInstrumentLevelOptimization()
  key <- "{\"planStart\": 1,\"planEnd\": 2,\"scenarioEnd\": 52,\"currentScenario\": 12}"
  value <- NA
  jsonList <- list()
  jsonList[[key]] <- value

  payLoad <- getBody(jsonList)
  jsonPayLoad <- fromJSON(payLoad)
  requiredParams <- list("planStart", "planEnd", "scenarioEnd", "currentScenario")

  req <- makeMockRequestObj("GET", requiredParams)

  output <- validateReqTypeAndParams("POST", req, requiredParams, jsonPayLoad)
  expect_false(output)
})
