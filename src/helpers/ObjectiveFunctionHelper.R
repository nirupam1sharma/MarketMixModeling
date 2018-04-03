GetOptimisedSpendsAndPressureUnitsFromGenoudWeights <- function(SourceFactors, wgts, AllMeasure, StartDate, EndDate) {
  # wgts <- rep(2,nrow(SourceFactors))
  OptimizedWts <- data.frame(SourceFactors,wgts)
  
  OptData <- data.table:::merge.data.table(AllMeasure,OptimizedWts,by=intersect(names(AllMeasure), names(OptimizedWts)),all=FALSE)
  
  AllData <- OptData[, c("OptInvestment","PressureUnit") :=
                      list(ifelse((StartDate <= Week & Week <= EndDate) & IsInScope == TRUE, Investment * wgts,Investment),
                            ifelse((StartDate <= Week & Week <= EndDate) & IsInScope == TRUE, PressureUnit * wgts,PressureUnit))]
  
  # MCT-752 can include wgts in the c() vector, since all activities in the instruments will have same wgts
  columnsForSpendInstrumentLevelTable <- names(AllData)[!names(AllData) %in% c("GrowthDriver", "ScenarioId", "Attributed_Investment", "Activity", "Investment", "OptInvestment", "PressureUnit", "Cost", "IsInScope")]
  AllData <- AllData[,lapply(.SD,sum,na.rm=TRUE),by=columnsForSpendInstrumentLevelTable,.SDcols=c('Investment', 'OptInvestment', 'Attributed_Investment', 'PressureUnit')]
  AllData <- AllData[order(Key,Week),]
  return(AllData)
}