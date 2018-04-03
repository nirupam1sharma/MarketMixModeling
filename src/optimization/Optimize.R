
Optimize = setRefClass("Optimize",
                       fields = list(),
                       methods = list(
                         optimizeScenario = function(payLoad) {
                           optimizationError <- FALSE;
                           optimizedSpend <- NULL
                           jsonPayLoad <- fromJSON(payLoad)
                           currentScenarioId <- jsonPayLoad$currentScenario$scenarioId
                           print(paste0("Optimizing for ScenarioId: ", currentScenarioId))
                           planStart <- jsonPayLoad[['startDate']]
                           planEnd <- jsonPayLoad[['planEnd']]
                           kpiId <- jsonPayLoad[['kpiId']]
                           scenarioEnd <- jsonPayLoad[['scenarioEnd']]
                           optimizeAtActivity <- jsonPayLoad[['optimizeAtActivity']]
                           tailInScenarioDt <- convertPayLoadToDataTable(payLoad, "tailInScenario", 0)
                           currentScenarioDt <- convertPayLoadToDataTable(payLoad, "currentScenario", planStart - 1)
                           Spend <- convertSpendToDataTable(rbind(currentScenarioDt, tailInScenarioDt))
                           con <- connectToDatabase(config)
                           MediaCost <- GetMediaCosts(con)
                           CurveParameter <- GetCurveParameters(con)
                           SecondaryKPIs <- GetSecondaryKPIs(con)
                           disconnectFromDatabase(con)
                           AllMeasure <- DataPrep(Spend, planStart, MediaCost, CurveParameter, SecondaryKPIs)
                           tailInScenarioId <- as.numeric(first(distinct(tailInScenarioDt, scenarioId)))
                           tryCatch({
                             optimizedSpend <- FinalOptimize(optimizeAtActivity, AllMeasure, payLoad, Spend, planStart, planEnd + planStart, tailInScenarioId, kpiId)
                             return (list(optimizedSpend=optimizedSpend, optimizationError=optimizationError))
                           }, error = function(e) {
                             print(paste0('Exception happened during Optimization !! ScenarioId: ', currentScenarioId))
                             print(e)
                             optimizationError <- TRUE
                             return (list(optimizationError=optimizationError))
                           })
                         }
                       ))
