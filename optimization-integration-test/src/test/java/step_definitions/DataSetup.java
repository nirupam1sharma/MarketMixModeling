package step_definitions;


import com.google.inject.Inject;
import cucumber.api.java.en.Given;
import cucumber.runtime.java.guice.ScenarioScoped;
import data.*;
import model.OptimizationContainer;

@ScenarioScoped
public class DataSetup {

    private final Dimensions dimensions;
    private final Calendar calendar;
    private final Model model;
    private final MediaCost mediaCost;
    private final SecKpiParams secKpiParams;
    private final SecondaryKpiFormula secondaryKpiFormula;
    private final TertiaryKpiFormula tertiaryKpiFormula;
    private final OptimizationContainer optimizationContainer;

    @Inject
    public DataSetup(Dimensions dimension, Calendar calendar, Model model, MediaCost mediaCost, SecKpiParams secKpiParams,
                     SecondaryKpiFormula secondaryKpiFormula, TertiaryKpiFormula tertiaryKpiFormula, OptimizationContainer optimizationContainer) {

        this.dimensions = dimension;
        this.calendar = calendar;
        this.model = model;
        this.mediaCost = mediaCost;
        this.secKpiParams = secKpiParams;
        this.secondaryKpiFormula = secondaryKpiFormula;
        this.tertiaryKpiFormula = tertiaryKpiFormula;
        this.optimizationContainer = optimizationContainer;
    }

    @Given("^I upload dimensions \"(\\S*)\"$")
    public void uploadDimensions(String fileName) throws Throwable {
        dimensions.upload(fileName);
    }

    @Given("^I upload calendar \"(\\S*)\"$")
    public void uploadCalendar(String fileName) throws Throwable {
        calendar.upload(fileName);
    }

    @Given("^I upload model \"(\\S*)\"$")
    public void uploadModel(String fileName) throws Throwable {
        model.upload(fileName);
    }

    @Given("^I upload media cost \"(\\S*)\"$")
    public void uploadMediaCost(String fileName) throws Throwable {
        mediaCost.upload(fileName);
    }

    @Given("^I upload secondary kpi params \"(\\S*)\" and setup secondary kpi \"(\\S*)\"$")
    public void uploadKpiParams(String fileName, String kpisFileName) throws Throwable {
        secKpiParams.upload(fileName);
        secondaryKpiFormula.addSecKpis(kpisFileName);
    }


    @Given("^I create secondary kpi which is equal to primary kpi$")
    public void createPrimaryKPI() throws Throwable {
        secondaryKpiFormula.addSecondaryKpiEqualToPrimaryKpi();
    }

    @Given("^I setup tertiary kpi \"([\\w\\s]+)\" with first secondary kpi$")
    public void uploadKpiParams(String kpiName) throws Throwable {
        String tertiaryKpiId = tertiaryKpiFormula.addTertiaryKpi(kpiName);
        optimizationContainer.setKpiIdToOptimize(tertiaryKpiId);
    }
}