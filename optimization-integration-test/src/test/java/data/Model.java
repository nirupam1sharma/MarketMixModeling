package data;

import com.google.inject.Inject;
import com.google.inject.Singleton;

import java.io.File;

import static com.jayway.restassured.RestAssured.given;

@Singleton
public class Model {

    private final SimulationApi simulationApi;

    @Inject
    public Model(SimulationApi simulationApi) {
        this.simulationApi = simulationApi;
    }

    public void upload(String fileName) {
        simulationApi.loadProperties();
        given()
                .header("username", "servicetest")
                .multiPart(new File(String.format("testData/modelConfig/%s", fileName)))
                .when()
                .post("/api/marketCurves")
                .then()
                .assertThat()
                .statusCode(200);
    }
}
