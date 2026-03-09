package com.rivo.functional;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

class OpenApiSpecContractTest {

    @Test
    void openApiSpecDocumentsCoreEndpointsAndContracts() throws IOException {
        ClassPathResource resource = new ClassPathResource("static/v3/api-docs.yaml");
        String yaml = new String(resource.getInputStream().readAllBytes(), StandardCharsets.UTF_8);

        assertTrue(yaml.contains("/api/v1/auth/login:"));
        assertTrue(yaml.contains("/api/v1/users:"));
        assertTrue(yaml.contains("/api/v1/route-requests/{id}/result:"));
        assertTrue(yaml.contains("/api/v1/locations:"));
        assertTrue(yaml.contains("/api/v1/incidents/{id}/vote:"));
        assertTrue(yaml.contains("/api/v1/pois:"));
        assertTrue(yaml.contains("Retry-After"));
        assertTrue(yaml.contains("ErrorResponse:"));
        assertTrue(yaml.contains("traceId:"));
    }
}