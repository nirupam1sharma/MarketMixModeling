package data;


import com.google.inject.Singleton;
import com.jayway.restassured.RestAssured;
import util.Properties;

@Singleton
public class OptimizationApi extends RestApiSetup  {
    @Override
    public void loadProperties() {
        Properties.load();
        RestAssured.baseURI = String.format("http://%s", Properties.current.getString("optimization_hostname"));
        RestAssured.port = Properties.current.getInt("optimization_port");
    }
}