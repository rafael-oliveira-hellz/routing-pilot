package com.rivo.integration;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.Test;

class FlywayMigrationSmokeTest {

    @Test
    void migratesSchemaWhenCiDatabaseIsAvailable() throws Exception {
        String url = System.getenv("CI_FLYWAY_URL");
        String user = System.getenv("CI_FLYWAY_USER");
        String password = System.getenv("CI_FLYWAY_PASSWORD");

        Assumptions.assumeTrue(url != null && !url.isBlank(), "CI_FLYWAY_URL not configured");

        Flyway flyway = Flyway.configure()
                .cleanDisabled(false)
                .dataSource(url, user, password)
                .locations("classpath:db/migration")
                .load();

        flyway.clean();
        var result = flyway.migrate();
        assertTrue(result.migrationsExecuted >= 1);

        try (Connection connection = DriverManager.getConnection(url, user, password);
             Statement statement = connection.createStatement()) {
            ResultSet rs = statement.executeQuery("select count(*) from flyway_schema_history where success = true");
            rs.next();
            assertEquals(result.migrationsExecuted, rs.getInt(1));
        }
    }
}