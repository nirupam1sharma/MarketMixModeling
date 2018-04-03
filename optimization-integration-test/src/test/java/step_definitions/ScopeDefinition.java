package step_definitions;


import com.google.inject.Inject;
import cucumber.api.java.en.And;
import cucumber.runtime.java.guice.ScenarioScoped;
import helper.DataHelper;
import helper.ScopeHelper;
import model.OptimizationContainer;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import static org.junit.Assert.assertEquals;

@ScenarioScoped
public class ScopeDefinition {

    private final JSONParser parser;
    private OptimizationContainer optimizationContainer;
    private ScopeHelper scopeHelper;
    private DataHelper dataHelper;

    @Inject
    public ScopeDefinition(OptimizationContainer optimizationContainer, ScopeHelper scopeHelper) {
        this.optimizationContainer = optimizationContainer;
        this.scopeHelper = scopeHelper;
        this.parser = new JSONParser();
        this.dataHelper = new DataHelper();
    }

    @And("^I deselect activity with name \"([^\"]*)\"$")
    public void deselectActivityUsingName(String activityName) throws ParseException {
        String optimizationPayload = optimizationContainer.getOptimizationPayload();
        JSONObject scenarioToBeOptimized = (JSONObject) this.parser.parse(optimizationPayload);
        this.scopeHelper.excludeActivity(activityName, scenarioToBeOptimized);
        optimizationContainer.setOptimizationPayload(scenarioToBeOptimized.toJSONString());
    }

    @And("^I assert optimized spend for \"([^\"]*)\" to be unchanged$")
    public void assertOptimizedSpendForToBeUnchanged(String activityName) throws Throwable {

        Double initialSpend = dataHelper.getTotalSpendForActivity(optimizationContainer.getActualScenarioDetails(),
                activityName);
        Double optimizedSpend = dataHelper.getTotalSpendForActivity(optimizationContainer.getOptimizedScenarioDetails(),
                activityName);
        assertEquals(initialSpend, optimizedSpend, 0);
    }
}