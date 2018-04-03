formatToOptimizationResult <- function(AllMeasure, SourceFactors, wts, tailInScenarioId, StartDate, EndDate, Spend)
{
  FinalizedWts <- data.frame(SourceFactors, wts)
  FinalOptData <- data.table:::merge.data.table(Spend, FinalizedWts, by = intersect(names(Spend), names(FinalizedWts)))
  data.table::setnames(
       FinalOptData,
       old = c('Investment'),
       new = c('Current_Investment')
     )
  FinalOptData <- data.table:::subset.data.table(FinalOptData,StartDate <= Week & Week <= EndDate)
  FinalOptData$wts[is.na(FinalOptData$wts)] <- 1
  
  ActivityLevelOptSpend <-
    FinalOptData[, ActLvlOptSpend := ifelse(Current_Investment == 0, 0, ifelse(IsInScope == FALSE, Investment, Current_Investment * wts))]

  ActivityLevelOptSpend[, c("Investment", "OptInvestment", "Current_Investment", "wts", "ActivityName", "GrowthDriverName", "IsInScope", "marketInstrumentLevelInvestmentForOutOfScopeActivities") := NULL]
  data.table::setnames(
    ActivityLevelOptSpend,
    old = c('ActLvlOptSpend'),
    new = c('Investment')
  )
  if(length(tailInScenarioId) != 0)  {
    ActivityLevelOptSpend <- ActivityLevelOptSpend[ActivityLevelOptSpend$ScenarioId != tailInScenarioId]
  }
  ActivityLevelOptSpend$Week <- ActivityLevelOptSpend$Week - StartDate
  
  names(ActivityLevelOptSpend) <-
    c(
      "marketId",
      "instrumentId",
      "activityId",
      "scenarioId",
      "campaignId",
      "weekNo",
      "weeklySpends"
    )
  return(ActivityLevelOptSpend)
}