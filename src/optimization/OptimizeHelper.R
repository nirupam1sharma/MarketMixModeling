
getBody <- function(params) {
  for (key in names(params)) {
    if (is.na(params[key])){
      return(key)
    }
  }
  return(NA)
}

validateReqTypeAndParams = function(httpMethod, reqObject, params, jsonPayLoad){
  return ((reqObject$request_method() == httpMethod) & (validateParams(params, jsonPayLoad)))
}

validateParams = function(params, jsonPayLoad) {
  for(param in params){
    if(is.null(jsonPayLoad[[param]])) return(FALSE);
  }
  return(TRUE);
}

createInstrumentConstraints <- function(payload) {
  data <- payload %>%
    as.tbl_json %>%
    enter_object("currentScenario") %>%
    enter_object("markets") %>%
    gather_array %>%
    spread_values(
      MarketId = jnumber("id")
    ) %>%
    enter_object("instruments") %>%
    gather_array %>%
    spread_values(
      Impact = jnumber("returns"),
      InstrumentId = jnumber("id")
    ) %>%
    enter_object("instrumentConstraints") %>%
    spread_values(
      Spend = jnumber("spend"),
      Min = jnumber("minSpend"),
      Max = jnumber("maxSpend")
    ) %>%
    select(MarketId, InstrumentId, Impact, Spend, Min, Max)
  dt <- data.table(data)
  return(dt)
}

createActivityConstraints <- function(payload) {
  data <- payload %>%
    as.tbl_json %>%
    enter_object("currentScenario") %>%
    enter_object("markets") %>%
    gather_array %>%
    spread_values(
      MarketId = jnumber("id")
    ) %>%
    enter_object("instruments") %>%
    gather_array %>%
    spread_values(
      InstrumentId = jnumber("id")
    ) %>%
    enter_object("campaigns") %>%
    gather_array %>%
    enter_object("activities") %>%
    gather_array %>%
    spread_values(
      Impact = jnumber("returns"),
      Activity = jnumber("activityId")
    ) %>%
    enter_object("activityConstraints") %>%
    spread_values(
      Spend = jnumber("spend"),
      Min = jnumber("minSpend"),
      Max = jnumber("maxSpend")
    ) %>%  
    select(MarketId, InstrumentId, Activity, Impact, Spend, Min, Max)
  dt <- data.table(data)
  return(dt)
}


createMarketConstraints <- function(payload) {
  data <- payload %>%
    as.tbl_json %>%
    enter_object("currentScenario") %>%
    enter_object("markets") %>%
    gather_array %>%
    spread_values(
      MarketId = jnumber("id"),
      Impact = jnumber("returns")
    ) %>%
    enter_object("marketConstraints") %>%
    spread_values(
      Spend = jnumber("spend"),
      Min = jnumber("minSpend"),
      Max = jnumber("maxSpend")
    ) %>%
    select(MarketId, Min, Max, Spend, Impact)
  dt <- data.table(data)
  return(dt)
}

createPortfolioConstraints <- function(payload) {
  data <- payload %>%
    as.tbl_json %>%
    enter_object("currentScenario") %>%
    spread_values(Impact = jnumber("returns")) %>%
    enter_object("portFolioConstraints") %>%
    spread_values(
      Spend = jnumber("spend"),
      Min = jnumber("minSpend"),
      Max = jnumber("maxSpend")
    ) %>%
    select(Min, Max, Impact, Spend)
  dt <- data.table(data)
  return(dt)
}

convertPayLoadToDataTable <- function(payLoad, key, startDate) {
  data <- payLoad %>%
    as.tbl_json %>%
    enter_object(key) %>%
    spread_values(scenarioId = jstring("scenarioId")) %>%
    enter_object("markets") %>%
    gather_array %>%
    spread_values(marketId = jnumber("id")) %>%
    enter_object("instruments") %>%
    gather_array %>%
    spread_values(instrumentId = jnumber("id")) %>%
    enter_object("campaigns") %>%
    gather_array %>%
    spread_values(
      campaignId = jnumber("id"),
      campaignName = jstring("name")
    ) %>%
    enter_object("activities") %>%
    gather_array %>%
    spread_values(
      activityId = jnumber("activityId"),
      activityName = jstring("name"),
      startWeek = jnumber("startWeek"),
      endWeek = jnumber("endWeek"), 
      isInScope = jlogical('isInScope')
    ) %>%
    enter_object("weeklySpends") %>%
    gather_array %>%
    append_values_number("weeklySpends")
  
  dt <- data.table(data)
  dt$startWeek <- dt$startWeek + startDate
  dt$weekNo <- dt$startWeek + dt$array.index - 1
  dt$document.id <- NULL
  dt$array.index <- NULL
  dt$startWeek <- NULL
  dt$endWeek <- NULL
  return(dt)
}

convertSpendToDataTable <- function(spend) {
  names(spend) <-
    c(
      "ScenarioId",
      "MarketId",
      "InstrumentId",
      "GrowthDriver",
      "GrowthDriverName",
      "Activity",
      "ActivityName",
      "IsInScope",
      "Investment",
      "Week"
    )
  return(spend)
}