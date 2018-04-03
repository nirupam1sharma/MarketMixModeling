HealthChecker = setRefClass("HealthChecker",
                             fields = list(),
                             methods = list(
                               ping= function() {
                                 return("pong");
                               }
                             )
)
