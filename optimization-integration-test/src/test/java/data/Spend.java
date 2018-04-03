package data;

import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.jayway.restassured.response.Response;

import java.io.File;

import static com.jayway.restassured.RestAssured.given;

@Singleton
public class Spend {

    private final SimulationApi simulationApi;

    @Inject
    public Spend(SimulationApi simulationApi) {
        this.simulationApi = simulationApi;
    }

    public String insertPreviousSpends(String fileName) {
        simulationApi.loadProperties();
        Response response = given()
                .header("username", "servicetest")
                .multiPart(new File(String.format("testData/spends/previousSpend/%s", fileName)))
                .when()
                .post("/api/scenarios");

        response.then()
                .assertThat()
                .statusCode(200);
        return getScenarioIdOfDefaultScenario();
    }

    public void insertCurrentYearPlan(String fileName, String scenarioId) {
        simulationApi.loadProperties();
        Response response = given()
                .header("username", "servicetest")
                .multiPart(new File(String.format("testData/spends/currentYear/%s", fileName)))
                .when()
                .post(String.format("/api/scenarios/%s", scenarioId));

        response.then()
                .assertThat()
                .statusCode(200);
    }

    private String getScenarioIdOfDefaultScenario() {
        Response response = given()
                .header("username", "servicetest")
                .get("/dev/getDefaultScenario");

        return response.getBody().asString();
    }
}
