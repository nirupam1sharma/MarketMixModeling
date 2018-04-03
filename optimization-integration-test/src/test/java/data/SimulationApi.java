package data;


import com.google.inject.Singleton;
import com.jayway.restassured.RestAssured;
import util.Properties;

@Singleton
public class SimulationApi extends RestApiSetup {
    @Override
    public void loadProperties() {
        Properties.load();
        RestAssured.baseURI = String.format("http://%s", Properties.current.getString("simulation_hostname"));
        RestAssured.port = Properties.current.getInt("simulation_port");
    }
}