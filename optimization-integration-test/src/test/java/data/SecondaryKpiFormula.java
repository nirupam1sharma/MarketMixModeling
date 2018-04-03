package data;

import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.jayway.restassured.response.Response;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import static com.jayway.restassured.RestAssured.given;

@Singleton
public class SecondaryKpiFormula {

    private final SimulationApi simulationApi;

    @Inject
    public SecondaryKpiFormula(SimulationApi simulationApi) {
        this.simulationApi = simulationApi;
    }

    public void addSecKpis(String fileName) throws ParseException {
        simulationApi.loadProperties();
        Response response = given()
                .header("username", "servicetest")
                .multiPart(new File(String.format("testData/marketKpiFormula/%s", fileName)))
                .when()
                .post("/api/formulas");

        response.then()
                .assertThat()
                .statusCode(200);
    }

    public void addSecondaryKpiEqualToPrimaryKpi() throws ParseException {
        simulationApi.loadProperties();

        Response response = given()
                .header("username", "servicetest")
                .contentType("application/json")
                .body(String.format("{\"kpiId\":null,\"kpiName\":\"%s\",\"variables\":null,\"formula\":\"\"}",
                        "PKPI"))
                .when()
                .post("/api/secondary-kpi/add");

        response.then().assertThat().statusCode(200);
    }

    private Response getSecKpiMetrics() {
        return given()
                .header("username", "servicetest")
                .contentType("application/json")
                .when()
                .get("api/secondary-kpi/metrics");
    }
}
