package util;

import org.apache.commons.configuration2.Configuration;
import org.apache.commons.configuration2.FileBasedConfiguration;
import org.apache.commons.configuration2.PropertiesConfiguration;
import org.apache.commons.configuration2.builder.FileBasedConfigurationBuilder;
import org.apache.commons.configuration2.builder.fluent.Parameters;
import org.apache.commons.configuration2.ex.ConfigurationException;

public class Properties {

    public static Configuration current;

    public static void load() {
        Parameters params = new Parameters();
        FileBasedConfigurationBuilder<FileBasedConfiguration> builder =
                new FileBasedConfigurationBuilder<FileBasedConfiguration>(PropertiesConfiguration.class)
                        .configure(params.properties()
                                .setFileName(String.format("%s.properties", getEnv())));
        try
        {
            current = builder.getConfiguration();
        }
        catch(ConfigurationException cex) {
            throw new RuntimeException("Encountered error while reading properties");
        }
    }

    private static String getEnv() {
        String env = System.getProperty("env");
        return env == null ? "dev": env;
    }
}
