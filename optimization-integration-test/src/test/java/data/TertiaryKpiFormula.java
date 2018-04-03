package data;

import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.jayway.restassured.response.Response;
import cucumber.runtime.java.guice.ScenarioScoped;
import model.OptimizationContainer;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import static com.jayway.restassured.RestAssured.given;

@Singleton
public class TertiaryKpiFormula {
    private final SimulationApi simulationApi;

    @Inject
    public TertiaryKpiFormula(SimulationApi simulationApi) {
        this.simulationApi = simulationApi;
    }
    public String addTertiaryKpi(String kpiName) throws ParseException {
        simulationApi.loadProperties();
        String formula;
        Response response = getSecKpis();
        response.then().assertThat().statusCode(200);
        JSONArray kpis = (JSONArray) new JSONParser().parse(response.getBody().asString());
        int metric1 = Integer.parseInt(((JSONObject) kpis.get(0)).get("kpiId").toString());
        formula = metric1 + "";
        Response tertiaryKpiResponse = given()
                .header("username", "servicetest")
                .contentType("application/json")
                .body(String.format("{\"secKpiId\":null,\"kpiId\":%s,\"kpiName\":\"%s\",\"variables\":null," +
                        "\"formula\":\"%s\"}", metric1, kpiName, formula))
                .when()
                .post("/api/tertiary-kpi");

        tertiaryKpiResponse.then().assertThat().statusCode(200);
        JSONObject tertiaryKpiFormula = (JSONObject) new JSONParser().parse(tertiaryKpiResponse.getBody().asString());
        String tertiaryKpiId = tertiaryKpiFormula.get("kpiId").toString();
        return tertiaryKpiId;
    }

    private Response getSecKpis() {
        return given()
                .header("username", "servicetest")
                .contentType("application/json")
                .when()
                .get("api/secondary-kpi/formulae");
    }
}
