package step_definitions;


import builder.MarketDetailsBuilder;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.inject.Inject;
import cucumber.api.java.en.And;
import cucumber.api.java.en.When;
import cucumber.runtime.java.guice.ScenarioScoped;
import data.Kpis;
import data.OptimizeScenario;
import helper.ConstrainedOptimizationHelper;
import model.MarketDetail;
import model.OptimizationContainer;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import java.util.Map;

@ScenarioScoped
public class OptimizationDefinition {
    private final JsonParser parser;
    private final OptimizeScenario optimizeScenario;
    private final OptimizationContainer optimizationContainer;
    private final MarketDetailsBuilder marketDetailsBuilder;
    private final Kpis kpis;
    private final ConstrainedOptimizationHelper constrainedOptimizationHelper;

    @Inject
    public OptimizationDefinition(OptimizeScenario optimizeScenario,
                                  OptimizationContainer optimizationContainer,
                                  MarketDetailsBuilder marketDetailsBuilder,
                                  Kpis kpis,
                                  ConstrainedOptimizationHelper constrainedOptimizationHelper) {
        this.optimizeScenario = optimizeScenario;
        this.optimizationContainer = optimizationContainer;
        this.marketDetailsBuilder = marketDetailsBuilder;
        this.kpis = kpis;
        this.constrainedOptimizationHelper = constrainedOptimizationHelper;
        this.parser = new JsonParser();

    }

    @When("^I run optimization for the scenario$")
    public void optimize() throws Throwable {

        String optimizationPayload = optimizationContainer.getOptimizationPayload();
        String optimizedSpends = optimizeScenario.optimize(optimizationPayload);
        optimizedSpends = optimizedSpends.replaceAll("Successfully finished Optimization for ScenarioId: [0-9]+", "");
        optimizationContainer.setOptimizedSpends(optimizedSpends);
    }

    @When("^I run optimization at activity level for the scenario$")
    public void optimizeAtActivityLevel() throws Throwable {

        String optimizationPayload = optimizationContainer.getOptimizationPayload();
        JsonObject payload = (JsonObject) parser.parse(optimizationPayload);
        payload.addProperty("optimizeAtActivity", true);
        String optimizedSpends = optimizeScenario.optimize(payload.toString());
        optimizedSpends = optimizedSpends.replaceAll("Successfully finished Optimization for ScenarioId: [0-9]+", "");
        optimizationContainer.setOptimizedSpends(optimizedSpends);
    }

    @And("^I fetch and store optimized scenario details$")
    public void fetchOptimizedScenarioDetails() throws ParseException {
        Map<String, MarketDetail> optimizedMarketDetails = marketDetailsBuilder.build();
        optimizationContainer.setOptimizedScenarioDetails(optimizedMarketDetails);
    }
}