package data;

import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.jayway.restassured.http.ContentType;
import com.jayway.restassured.response.Response;
import helper.DataHelper;

import static com.jayway.restassured.RestAssured.given;

@Singleton
public class UpdateScenario {
    private final SimulationApi simulationApi;

    @Inject
    public UpdateScenario(SimulationApi simulationApi) {
        this.simulationApi = simulationApi;
    }

    public void updateSpend(String spend, String scenarioId) {
        simulationApi.loadProperties();
        Response modelResponse = given()
                .header("username", "servicetest")
                .contentType(ContentType.JSON)
                .body(spend)
                .when()
                .put(String.format("/dev/scenarios/%s", scenarioId));

        modelResponse.then().assertThat().statusCode(200);
    }

    public String updateInstrumentSpend(String scenarioId, String marketId, String instrumentId, Double spend) {
        simulationApi.loadProperties();
        Response marketDetails = given()
                .header("username", "servicetest")
                .contentType("application/json")
                .body(String.format("{\"spend\":%f}", spend))
                .when()
                .put(String.format("/api/scenarios/%s/market/%s/instruments/%s", scenarioId, marketId,
                        instrumentId));

        marketDetails.then().assertThat().statusCode(200);
        return marketDetails.getBody().asString();
    }
}
