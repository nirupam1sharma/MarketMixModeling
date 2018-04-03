package step_definitions;

import com.google.inject.Inject;
import cucumber.api.java.en.Given;
import cucumber.runtime.java.guice.ScenarioScoped;
import data.Spend;
import model.OptimizationContainer;

@ScenarioScoped
public class SpendSetup {

    private final Spend spend;
    private final OptimizationContainer optimizationContainer;

    @Inject
    public SpendSetup(Spend spend, OptimizationContainer optimizationContainer) {
        this.spend = spend;
        this.optimizationContainer = optimizationContainer;
    }

    @Given("^I upload previous year spend \"(\\S*)\"$")
    public void insertPreviousSpend(String fileName) throws Throwable {
        String scenarioId = spend.insertPreviousSpends(fileName);
        optimizationContainer.setScenarioId(scenarioId);
    }

    @Given("^I upload current year plan \"(\\S*)\"$")
    public void insertCurrentYearPlan(String fileName) throws Throwable {
        spend.insertCurrentYearPlan(fileName, optimizationContainer.getScenarioId());
    }
}
