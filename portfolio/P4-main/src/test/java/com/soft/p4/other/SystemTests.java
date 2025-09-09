package com.soft.p4.other;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

/**
 * System test suite for real hardware integration. Tests actual Hue Bridge
 * connectivity and light control operations. Skipped in CI environments to
 * avoid hardware dependencies.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Tag("systemTest")
public class SystemTests {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    public void testRealConnectionToBridge() {
        // Skip in CI environment
        if (System.getenv("CI") != null) {
            System.out.println("Skipping system test in CI environment");
            return;
        }

        // Test connection to actual bridge
        String url = "http://localhost:" + port + "/api/scripts/test-connection";
        ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);

        assertEquals(200, response.getStatusCode().value(), "Response status should be 200");
        assertNotNull(response.getBody(), "Response body should not be null");

        // Log result - don't assert on connected state since it depends on environment
        boolean connected = (Boolean) response.getBody().get("connected");
        System.out.println("Bridge connection test result: " + (connected ? "CONNECTED" : "NOT CONNECTED"));
    }

    @Test
    public void testBasicLightCommands() {
        // Skip in CI environment
        if (System.getenv("CI") != null) {
            System.out.println("Skipping system test in CI environment");
            return;
        }

        // Base URL
        String baseUrl = "http://localhost:" + port;

        // Check connection first
        ResponseEntity<Map> connectionResponse = restTemplate.getForEntity(
                baseUrl + "/api/scripts/test-connection", Map.class);

        if (connectionResponse.getBody() == null || !(Boolean) connectionResponse.getBody().get("connected")) {
            System.out.println("Skipping test because bridge is not connected");
            return;
        }

        // Run simple script to test light control
        String scriptUrl = baseUrl + "/api/scripts/execute";
        String script = "lights on;\n"
                + "brightness 30;\n"
                + "lights color \"#00BFFF\";\n"
                + "wait 2 sec;\n"
                + "lights off;";

        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("scriptContent", script);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, String>> request = new HttpEntity<>(requestBody, headers);

        ResponseEntity<Map> response = restTemplate.postForEntity(scriptUrl, request, Map.class);

        assertEquals(200, response.getStatusCode().value(), "Response status should be 200");
        assertNotNull(response.getBody(), "Response body should not be null");

        // Log script execution output
        String log = (String) response.getBody().get("log");
        boolean success = (Boolean) response.getBody().get("success");

        System.out.println("Script execution result: " + (success ? "SUCCESS" : "FAILED"));
        System.out.println("Execution log:");
        System.out.println(log);
    }
}
