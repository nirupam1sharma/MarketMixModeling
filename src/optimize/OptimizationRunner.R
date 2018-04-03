source('src/optimization/Optimizer.R')

OptimizationRunner = setRefClass('OptimizationRunner', fields=list(), contains=list("Optimizer"),
  methods=list(
    Optimize = function(Constraint, StartDate, EndDate, KPIFormula){
      SourceBased <- Constraint$SourceBased
      SourceFactors <- Constraint$getSourceFactorsWithDropScopeConstraint()
      StartingValue <- Constraint$getStartingValue()
      OCurrentInscopeWithConst <- Constraint$getCurrentInScope()
      limit <- Constraint$getLimit() 
      AllMeasure <- Constraint$getAllMeasure()
      start <- StartDate
      end <- EndDate
     
      getObjfunction <- function(PenaltyLambda) {
        return(
          function(wgts) {
            AllDataWithOptimisedKpi <- PopulateKpi(SourceFactors, wgts, AllMeasure, StartDate, EndDate, FunctionalForm, ParsedFunctionalForm, KPIFormula)
            TotalPenalty <- PenaltyLambda(AllDataWithOptimisedKpi)
            Obj.Function.Value <- AllDataWithOptimisedKpi[,sum(TertiaryKPI)] - TotalPenalty
            return(Obj.Function.Value)
          })
      }
      
      PenaltyLambda <- Constraint$getComputePenaltyLambda()
      Objfunction <- getObjfunction(PenaltyLambda)
      FirstCutOutput <- OptEngine(MAX_POPULATION_SIZE, debugLevel, unif_seed, int_seed, NoWorkers, SourceFactors, wait_generations1, StartingValue, OptMaxorMin, Objfunction, limit)
      
      SecondStartingValue <- Constraint$getSecondStartingValue(FirstCutOutput)
      Constraint$computePF(PrecisionInBudget2)
      PenaltyLambda <- Constraint$getComputePenaltyLambda()
      Objfunction <- getObjfunction(PenaltyLambda)

      Finalwts <- OptEngine(MAX_POPULATION_SIZE, debugLevel, unif_seed, int_seed, NoWorkers, SourceFactors, wait_generations2, SecondStartingValue, OptMaxorMin, Objfunction, limit)
      SourceFactors$Finalwts <- Finalwts

      FixedBudgetFinalWts <- Constraint$getFixedBudgetFinalWts()
      marketInstrumentWithFinalwts <- rbind(SourceFactors, FixedBudgetFinalWts)

      setorderv(marketInstrumentWithFinalwts, SourceBased)
      SourceFactors <- OCurrentInscopeWithConst[,SourceBased,with=FALSE]
      setorderv(SourceFactors, SourceBased)
      return(list(Finalwts=marketInstrumentWithFinalwts$Finalwts, SourceFactorsWithDropScopeConstraint=SourceFactors, AllMeasure=AllMeasure))
    }
   ))
