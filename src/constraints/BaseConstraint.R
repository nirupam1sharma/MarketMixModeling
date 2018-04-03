BaseConstraint = setRefClass('BaseConstraint',
                                         fields=list(lb = "numeric", ub = "numeric", limit = "matrix",
                                                     StartingValue = "numeric", OCurrentInscopeWithConst = "data.table", AllMeasure = "data.table",
                                                     SourceFactorsWithDropScopeConstraint = "data.table", StartDate = "numeric",
                                                     EndDate = "numeric", SourceBased = "character"),
                             contains=list("Optimizer"), 
                                         
methods=list(
  
  getlb = function() { return (lb) },
  
  getUb = function() { return (ub) },
  
  getLimit = function() { return (limit) },
  
  getStartingValue = function() { return (StartingValue) },
  
  getCurrentInScope = function() { return (OCurrentInscopeWithConst) },
  
  getAllMeasure = function() { return (AllMeasure) },
  
  getSourceFactorsWithDropScopeConstraint = function() { return (SourceFactorsWithDropScopeConstraint) }
))