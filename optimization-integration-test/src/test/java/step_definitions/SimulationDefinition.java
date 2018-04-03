package step_definitions;

import builder.MarketDetailsBuilder;
import com.google.inject.Inject;
import cucumber.api.java.en.And;
import cucumber.runtime.java.guice.ScenarioScoped;
import data.UpdateScenario;
import model.MarketDetail;
import model.OptimizationContainer;
import org.json.simple.parser.ParseException;

import java.util.Map;

@ScenarioScoped
public class SimulationDefinition {

    private final OptimizationContainer optimizationContainer;
    private final UpdateScenario updateScenario;
    private final MarketDetailsBuilder marketDetailsBuilder;

    @Inject
    public SimulationDefinition(OptimizationContainer optimizationContainer,
                                UpdateScenario updateScenario, MarketDetailsBuilder marketDetailsBuilder) {
        this.optimizationContainer = optimizationContainer;
        this.updateScenario = updateScenario;
        this.marketDetailsBuilder = marketDetailsBuilder;
    }

    @And("^I fetch and store the actual scenario details$")
    public void fetchActualScenarioDetails() throws ParseException {
        Map<String, MarketDetail> actualScenarioDetails = marketDetailsBuilder.build();
        optimizationContainer.setActualScenarioDetails(actualScenarioDetails);
    }

    @And("^I updated the scenario with optimized spends$")
    public void updateScenarioDetails() throws Throwable {
        String optimizedSpends = optimizationContainer.getOptimizedSpends();
        String scenarioId = optimizationContainer.getScenarioId();
        this.updateScenario.updateSpend(optimizedSpends, scenarioId);
    }
}
