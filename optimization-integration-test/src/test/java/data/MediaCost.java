package data;

import com.google.inject.Inject;
import com.google.inject.Singleton;

import java.io.File;

import static com.jayway.restassured.RestAssured.given;

@Singleton
public class MediaCost {

    private final SimulationApi simulationApi;

    @Inject
    public MediaCost(SimulationApi simulationApi) {
        this.simulationApi = simulationApi;
    }

    public void upload(String fileName) {
        simulationApi.loadProperties();
        given()
                .header("username", "servicetest")
                .multiPart(new File(String.format("testData/mediaCosts/%s", fileName)))
                .when()
                .post("/api/importMarketLevelMediaCosts")
                .then()
                .assertThat()
                .statusCode(200);
    }
}
