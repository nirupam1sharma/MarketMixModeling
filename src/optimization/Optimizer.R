
Optimizer = setRefClass("Optimizer",
fields=list(
FunctionalForm = "list",
ParsedFunctionalForm = "list",
OptMaxorMin = "logical",
wait_generations1 = "numeric",
wait_generations2 = "numeric",
PrecisionInBudget1 = "numeric",
PrecisionInBudget2 = "numeric",
LowerLimit = "numeric",
UpperLimit = "numeric",
MAX_POPULATION_SIZE = "numeric",
debugLevel = "logical",
unif_seed = "numeric",
int_seed = "numeric",
NoWorkers = "numeric"
),
methods=list(
initialize = function() {
    FunctionalForm <<- fromJSON("./FunctionalForm.json")
    ParsedFunctionalForm <<- list()
    for(i in seq_along(FunctionalForm)) {
        ParsedFunctionalForm[[i]] <<- parse(text = FunctionalForm[[i]])
    }
    OptMaxorMin <<- TRUE
    wait_generations1     <<- as.numeric(config[['wait_generations1']])
    wait_generations2     <<- as.numeric(config[['wait_generations2']])
    LowerLimit            <<- as.numeric(config[['LowerLimit']])
    UpperLimit            <<- as.numeric(config[['UpperLimit']])
    PrecisionInBudget1    <<- as.numeric(config[['PrecisionInBudget1']])
    PrecisionInBudget2    <<- as.numeric(config[['PrecisionInBudget2']])
    MAX_POPULATION_SIZE   <<- 10000
    debugLevel 			      <<- TRUE
    unif_seed             <<- 923932
    int_seed              <<- 64169
    NoOfCores             <- detectCores()
    NoWorkers             <<- ifelse(NoOfCores > 2, NoOfCores - 1, NoOfCores)
}
))
