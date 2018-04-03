package data;

import com.google.inject.Inject;
import com.google.inject.Singleton;
import org.json.simple.parser.ParseException;

import java.io.File;

import static com.jayway.restassured.RestAssured.given;

@Singleton
public class Dimensions {
    private final SimulationApi simulationApi;

    @Inject
    public Dimensions(SimulationApi simulationApi) {
        this.simulationApi = simulationApi;
    }

    public void upload(String fileName) throws ParseException {
        simulationApi.loadProperties();
        given()
                .header("username", "servicetest")
                .multiPart(new File(String.format("testData/dimensions/%s", fileName)))
                .when()
                .post("/api/dimensions")
                .then()
                .assertThat()
                .statusCode(200);
    }
}
