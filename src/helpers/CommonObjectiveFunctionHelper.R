AdStockCalculation <- function(PressureUnit,carryOver, lag, total.rows)
{
  temp_ <- data.table::shift(c(1,dgeom(1:(total.rows-1),(1-carryOver),log=F)/(1-carryOver)), 0:total.rows, fill=0)
  CarryoverMatriX <- matrix(unlist(temp_), nrow=total.rows,ncol = total.rows, byrow = FALSE)
  AdStock_Series <- data.table::shift(c(CarryoverMatriX %*% PressureUnit), lag, fill=0)
  return(AdStock_Series)
}

AttributedImpactCalculation <- function(PressureUnit, PUAdStockratio, carryOver, lag, total.rows,SecKPIValues)
{
  temp_ <- data.table::shift(c(1,dgeom(1:(total.rows-1),(1-carryOver),log=F)/(1-carryOver)), 0:total.rows, fill=0)
  CarryoverMatriX <- matrix(unlist(temp_), nrow=total.rows,ncol = total.rows, byrow = TRUE)
  AttributedSeries <- data.table::shift(PressureUnit, lag, fill=0) * CarryoverMatriX %*% (PUAdStockratio * SecKPIValues)
  return(AttributedSeries)
}

GetOptimisedAttributedInvestumentAndModelKpi <- function(AllDataWithOptimisedAdStock, FunctionalForm, ParsedFunctionalForm){
  for( i in seq_along(FunctionalForm)) {
    KPIMetrics <- AllDataWithOptimisedAdStock[functionalFormName==names(FunctionalForm)[[i]],c("AttributedInvestment","ModelKPI") := list(OptInvestment/XEffectf,eval(ParsedFunctionalForm[[i]]))]
  }
  KPIMetrics <- KPIMetrics[,PressureUnitAdStockRatio := ifelse(AdStock==0, 0,ModelKPI/AdStock)]
  KPIMetrics <- KPIMetrics[order(Key, Week),]
  return(KPIMetrics)
}

GetOptimisedAdstock <- function(AllDataWithOptimisedSpendsAndPressureUnits) {
  AllDataWithOptimisedSpendsAndPressureUnits[, AdStock := AdStockCalculation(PressureUnit[1:.N], Carryover[1], Lag[1], .N),by=Key]
  return(AllDataWithOptimisedSpendsAndPressureUnits)
}

GetOptimisedTertiaryKpi <- function(KPIFormula, AllDataWithOptimisedPrimaryKpi) {
  SecKPIMetrics <- data.table(KPIFormula)
  SecKPIMetrics[, 'formula' := strsplit(formula, "[+-]AttributedInvestment") ]
  SecKPIMetrics[, 'SeconadryKpis' := list(strsplit(formula[[1]], "[*]")), by = 1:nrow(SecKPIMetrics)]
  SecKPIMetrics[,SecKpiValues := ifelse(length(SeconadryKpis[[1]]) > 0, paste0(paste0(unlist(SeconadryKpis), collapse = "[1:.N] *  "),'[1:.N]'), "1"), by = 1:nrow(SecKPIMetrics)]
  AllDataWithOptimisedPrimaryKpi[, AttributedImpact := AttributedImpactCalculation(PressureUnit[1:.N],PressureUnitAdStockRatio[1:.N], Carryover[1],Lag[1], .N, eval(parse(text=SecKPIMetrics[market_id==ReceivingMarketId[1]]$SecKpiValues[1]), envir = .SD)), by=Key]
  TertiaryKPIFormula <- 'AttributedImpact-AttributedInvestment'
  if (KPIFormula$kpi_type[1] == 'Secondary Kpi') {
    TertiaryKPIFormula <- 'AttributedImpact'
  }
  AllDataWithOptimisedPrimaryKpi[,TertiaryKPI:= eval(parse(text=TertiaryKPIFormula))]
  return(AllDataWithOptimisedPrimaryKpi)
}

PopulateKpi <- function(SourceFactors, wgts, AllMeasure, StartDate, EndDate, FunctionalForm, ParsedFunctionalForm, KPIFormula) {
AllDataWithOptimisedSpendsAndPressureUnits <- GetOptimisedSpendsAndPressureUnitsFromGenoudWeights(SourceFactors, wgts, AllMeasure, StartDate, EndDate)
AllDataWithOptimisedAdStock <- GetOptimisedAdstock(AllDataWithOptimisedSpendsAndPressureUnits)
AllDataWithOptimisedPrimaryKpi <- GetOptimisedAttributedInvestumentAndModelKpi(AllDataWithOptimisedAdStock, FunctionalForm, ParsedFunctionalForm)
AllDataWithOptimisedTertiaryKpi <- GetOptimisedTertiaryKpi(KPIFormula, AllDataWithOptimisedPrimaryKpi)
return(AllDataWithOptimisedTertiaryKpi)
}

# MCT-752 Used function names 'GetOptimisedSpendsAndPressureUnitsFromGenoudWeights' ( which will be in individual source files ) not yet initialised.
FunctionsToCopyToAllClusters <- c('PopulateKpi', 'AdStockCalculation', 'AttributedImpactCalculation', 'GetOptimisedSpendsAndPressureUnitsFromGenoudWeights', 'GetOptimisedAttributedInvestumentAndModelKpi', 'GetOptimisedAdstock', 'GetOptimisedTertiaryKpi')