package step_definitions;


import com.google.inject.Inject;
import cucumber.api.java.en.And;
import cucumber.api.java.en.Given;
import cucumber.api.java.en.Then;
import cucumber.runtime.java.guice.ScenarioScoped;
import data.ScenarioDetails;
import helper.ConstrainedOptimizationHelper;
import model.MarketDetail;
import model.OptimizationContainer;
import model.PortfolioConstraints;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.junit.Assert;

import java.util.Map;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.greaterThan;

@ScenarioScoped
public class UnConstrainedOptimizationDefinition {

    private final OptimizationContainer optimizationContainer;
    private final ScenarioDetails scenarioDetails;
    private final ConstrainedOptimizationHelper constrainedOptimizationHelper;
    private final org.json.simple.parser.JSONParser parser;

    @Inject
    public UnConstrainedOptimizationDefinition(OptimizationContainer optimizationContainer, ScenarioDetails
            scenarioDetails, ConstrainedOptimizationHelper constrainedOptimizationHelper) {
        this.optimizationContainer = optimizationContainer;
        this.scenarioDetails = scenarioDetails;
        this.constrainedOptimizationHelper = constrainedOptimizationHelper;
        this.parser = new org.json.simple.parser.JSONParser();
    }

    @Given("^I fetch the unconstrained optimization payload$")
    public void buildUnconstrainedOptimizationPayload() throws Throwable {
        String scenarioDetails = this.scenarioDetails.fetch(optimizationContainer.getScenarioId(),
                optimizationContainer.getKpiIdToOptimize());

        JSONObject scenarioToBeOptimized = (JSONObject) parser.parse(scenarioDetails);
        JSONObject constraintDetails = (JSONObject) parser
                .parse(this.scenarioDetails.fetchConstraints(optimizationContainer.getScenarioId()));
        JSONObject portfolioConstraintDetails = (JSONObject) constraintDetails.get("portfolioDetails");
        JSONArray marketConstraintDetails = (JSONArray) constraintDetails.get("marketDetails");
        ((JSONObject) scenarioToBeOptimized.get("currentScenario")).put("portFolioConstraints", portfolioConstraintDetails);

        JSONArray marketsDetail = (JSONArray) (
                (JSONObject) scenarioToBeOptimized.get("currentScenario")
        ).get("markets");

        marketConstraintDetails.forEach(marketConstraint -> {
                    JSONObject marketConstraintJson = (JSONObject) marketConstraint;
                    long marketConstraintId = (long) marketConstraintJson.get("id");

                    JSONObject market = (JSONObject) marketsDetail
                            .stream()
                            .filter(marketDetail -> {
                                long marketDetailId = (long) ((JSONObject) marketDetail).get("id");
                                return marketDetailId == marketConstraintId;
                            }).findFirst().get();

                    market.put("marketConstraints", marketConstraintJson);

                    JSONArray instrumentConstraints = (JSONArray) ((JSONObject) marketConstraint).get
                            ("childConstraints");
                    JSONArray marketInstrumentsDetail = (JSONArray) market.get("instruments");

                    marketInstrumentsDetail.forEach(marketInstrument -> {
                        long instrumentId = (long) ((JSONObject) marketInstrument).get("id");
                        JSONObject instrument = (JSONObject) instrumentConstraints.stream().filter(instrumentConstraint -> {
                            long instrumentConstraintId = (long) ((JSONObject) instrumentConstraint).get("id");
                            return instrumentConstraintId == instrumentId;
                        }).findFirst().get();
                        ((JSONObject) marketInstrument).put("instrumentConstraints", instrument);


                        JSONArray activityConstraints = (JSONArray) instrument.get("childConstraints");
                        JSONArray campaigns = (JSONArray) ((JSONObject)marketInstrument).get("campaigns");
                        campaigns.forEach(campaign -> {
                            JSONArray activities = (JSONArray) ((JSONObject)campaign).get("activities");
                            activities.forEach(activity -> {
                                long activityId = (long) ((JSONObject) activity).get("activityId");
                                JSONObject activityConstraintDetails = (JSONObject) activityConstraints.stream()
                                        .filter(activityConstraint -> {
                                    long activityConstraintId = (long) ((JSONObject) activityConstraint).get("id");
                                    return activityConstraintId == activityId;
                                }).findFirst().get();
                                ((JSONObject) activity).put("activityConstraints", activityConstraintDetails);
                            });
                        });
                    });
        });

        PortfolioConstraints constraints = constrainedOptimizationHelper.
                getConstraintDetails(scenarioToBeOptimized.toJSONString());

        optimizationContainer.setOptimizationPayload(scenarioToBeOptimized.toJSONString());
        optimizationContainer.setOptimizationConstraints(constraints);
    }

    @Then("^I assert optimized portfolio spend greater than zero$")
    public void assertPortfolioSpends() throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        Double optimizedScenarioTotalSpends = optimizationContainer.getTotalSpend(optimizedScenarioDetails.values());
        Assert.assertTrue(optimizedScenarioTotalSpends.toString(), optimizedScenarioTotalSpends > 0);
    }

    @And("^I assert optimized selected kpi's mroi to be zero at instrument level$")
    public void assertSelectedKpisMroi() throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        for (MarketDetail marketDetail : optimizedScenarioDetails.values()) {
            marketDetail.getInstrumentDetails().values().stream().forEach(instrumentDetail -> {
                if (instrumentDetail.getAggregatedSpend() != 0.0) {
                    Assert.assertEquals(0.0, instrumentDetail.getSelectedKpiMarginalRoi(), 0.0001);
                }
            });
        }
    }



    @And("^I assert optimized selected kpi's returns to be greater than that of actual scenario$")
    public void assertSelectedKpisReturns() throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        Map<String, MarketDetail> actualScenarioDetails = optimizationContainer.getActualScenarioDetails();
        for(MarketDetail marketDetail : optimizedScenarioDetails.values()) {
            MarketDetail actualScenarioMarketDetail = actualScenarioDetails.get(marketDetail.getId());
            marketDetail.getInstrumentDetails().values().stream().forEach(instrumentDetail -> {
                if (actualScenarioMarketDetail
                        .getInstrumentDetails().get(instrumentDetail.getId()).getAggregatedSpend() > 0.0)
                assertThat(instrumentDetail.getSelectedKpiReturns(), greaterThan(actualScenarioMarketDetail
                        .getInstrumentDetails().get(instrumentDetail.getId()).getSelectedKpiReturns()));
            });
            assertThat(marketDetail.getSelectedKpiReturns(), greaterThan(actualScenarioMarketDetail.getSelectedKpiReturns()));
        }
    }

    @And("^I assert sum of optimized selected kpi's returns of all markets to be greater than that of actual scenario$")
    public void assertSumOfSelectedKpisReturns() throws Throwable {
        Double sumOfOptimizedSelectedKpiReturns = optimizationContainer.getOptimizedScenarioDetails()
                .values().stream()
                .mapToDouble(MarketDetail::getSelectedKpiReturns)
                .sum();
        Double sumOfActualSelectedKpiReturns = optimizationContainer.getActualScenarioDetails()
                .values().stream()
                .mapToDouble(MarketDetail::getSelectedKpiReturns)
                .sum();
        assertThat(sumOfOptimizedSelectedKpiReturns, greaterThan(sumOfActualSelectedKpiReturns));
    }

    @And("^I assert optimized \"([^\"]*)\" mroi to be (\\d+)$")
    public void iAssertOptimizedMroiToBe(String kpiName, int value) throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        for (MarketDetail marketDetail : optimizedScenarioDetails.values()) {
            marketDetail.getInstrumentDetails().values().stream().forEach(instrumentDetail -> {
                if (instrumentDetail.getAggregatedSpend() != 0.0) {
                    Assert.assertEquals(value, instrumentDetail.getSelectedKpiMarginalRoi(), 0.0001);
                }
            });
        }
    }
}