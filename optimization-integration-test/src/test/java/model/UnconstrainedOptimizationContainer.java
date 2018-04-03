package model;

import cucumber.runtime.java.guice.ScenarioScoped;
import lombok.Getter;
import lombok.Setter;

import java.util.Map;

@ScenarioScoped
@Setter
@Getter
public class UnconstrainedOptimizationContainer {
    private Map<String, MarketDetail> optimizedScenarioDetails;
}
