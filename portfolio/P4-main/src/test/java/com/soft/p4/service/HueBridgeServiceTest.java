package com.soft.p4.service;

import java.io.IOException;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

/**
 * Test suite for HueBridgeService functionality. Validates bridge
 * communication, light control, and color conversion operations.
 */
public class HueBridgeServiceTest {

    private HueBridgeService hueBridgeService;
    private RestTemplate mockRestTemplate;
    private ObjectMapper objectMapper;

    // Bridge info - must match hardcoded values in HueBridgeService
    private final String EXPECTED_BRIDGE_IP = "192.168.8.100";
    private final String EXPECTED_API_KEY = "11pToqtVvmoGFJUKshDTZcMChfEMfxDqu-FDB33A";

    @BeforeEach
    public void setUp() throws Exception {
        hueBridgeService = new HueBridgeService();
        mockRestTemplate = mock(RestTemplate.class);
        objectMapper = new ObjectMapper();

        // Use reflection to replace the restTemplate
        Field restTemplateField = HueBridgeService.class.getDeclaredField("restTemplate");
        restTemplateField.setAccessible(true);
        restTemplateField.set(hueBridgeService, mockRestTemplate);
    }

    @Test
    public void testSetAllLightsStateOn() throws IOException {
        // Mock response
        ResponseEntity<String> mockResponse = mock(ResponseEntity.class);
        when(mockResponse.getStatusCode()).thenReturn(org.springframework.http.HttpStatus.OK);
        when(mockRestTemplate.exchange(anyString(), any(HttpMethod.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(mockResponse);

        // Execute test
        hueBridgeService.setAllLightsState(true);

        // Verify request
        ArgumentCaptor<String> urlCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<HttpEntity<String>> entityCaptor = ArgumentCaptor.forClass(HttpEntity.class);
        verify(mockRestTemplate).exchange(
                urlCaptor.capture(),
                eq(HttpMethod.PUT),
                entityCaptor.capture(),
                eq(String.class));

        // Check URL and body
        String expectedUrl = String.format("http://%s/api/%s/groups/0/action", EXPECTED_BRIDGE_IP, EXPECTED_API_KEY);
        assertEquals(expectedUrl, urlCaptor.getValue(), "Should use correct URL");

        String requestBody = entityCaptor.getValue().getBody();
        ObjectNode bodyJson = (ObjectNode) objectMapper.readTree(requestBody);
        assertTrue(bodyJson.get("on").asBoolean(), "Request body should set lights ON");
    }

    @Test
    public void testSetAllLightsStateOff() throws IOException {
        // Mock response
        ResponseEntity<String> mockResponse = mock(ResponseEntity.class);
        when(mockResponse.getStatusCode()).thenReturn(org.springframework.http.HttpStatus.OK);
        when(mockRestTemplate.exchange(anyString(), any(HttpMethod.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(mockResponse);

        // Execute test
        hueBridgeService.setAllLightsState(false);

        // Verify request body
        ArgumentCaptor<HttpEntity<String>> entityCaptor = ArgumentCaptor.forClass(HttpEntity.class);
        verify(mockRestTemplate).exchange(
                anyString(),
                eq(HttpMethod.PUT),
                entityCaptor.capture(),
                eq(String.class));

        String requestBody = entityCaptor.getValue().getBody();
        ObjectNode bodyJson = (ObjectNode) objectMapper.readTree(requestBody);
        assertFalse(bodyJson.get("on").asBoolean(), "Request body should set lights OFF");
    }

    @Test
    public void testSetLightState() throws IOException {
        // Mock response
        ResponseEntity<String> mockResponse = mock(ResponseEntity.class);
        when(mockResponse.getStatusCode()).thenReturn(org.springframework.http.HttpStatus.OK);
        when(mockRestTemplate.exchange(anyString(), any(HttpMethod.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(mockResponse);

        // Execute test
        String lightId = "1";
        hueBridgeService.setLightState(lightId, true);

        // Verify request
        ArgumentCaptor<String> urlCaptor = ArgumentCaptor.forClass(String.class);
        verify(mockRestTemplate).exchange(
                urlCaptor.capture(),
                eq(HttpMethod.PUT),
                any(HttpEntity.class),
                eq(String.class));

        // Check URL format
        String expectedUrl = String.format("http://%s/api/%s/lights/%s/state", EXPECTED_BRIDGE_IP, EXPECTED_API_KEY, lightId);
        assertEquals(expectedUrl, urlCaptor.getValue(), "Should use correct URL");
    }

    @Test
    public void testSetAllLightsBrightness() throws IOException {
        // Mock response
        ResponseEntity<String> mockResponse = mock(ResponseEntity.class);
        when(mockResponse.getStatusCode()).thenReturn(org.springframework.http.HttpStatus.OK);
        when(mockRestTemplate.exchange(anyString(), any(HttpMethod.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(mockResponse);

        // Execute test
        int brightness = 200;
        hueBridgeService.setAllLightsBrightness(brightness);

        // Verify request body
        ArgumentCaptor<HttpEntity<String>> entityCaptor = ArgumentCaptor.forClass(HttpEntity.class);
        verify(mockRestTemplate).exchange(
                anyString(),
                eq(HttpMethod.PUT),
                entityCaptor.capture(),
                eq(String.class));

        String requestBody = entityCaptor.getValue().getBody();
        ObjectNode bodyJson = (ObjectNode) objectMapper.readTree(requestBody);
        assertEquals(brightness, bodyJson.get("bri").asInt(), "Request body should include correct brightness");
    }

    @Test
    public void testSetAllLightsColor() throws IOException {
        // Mock response
        ResponseEntity<String> mockResponse = mock(ResponseEntity.class);
        when(mockResponse.getStatusCode()).thenReturn(org.springframework.http.HttpStatus.OK);
        when(mockRestTemplate.exchange(anyString(), any(HttpMethod.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(mockResponse);

        // Execute test
        String hexColor = "#FF0000"; // Red
        hueBridgeService.setAllLightsColor(hexColor);

        // Verify request body
        ArgumentCaptor<HttpEntity<String>> entityCaptor = ArgumentCaptor.forClass(HttpEntity.class);
        verify(mockRestTemplate).exchange(
                anyString(),
                eq(HttpMethod.PUT),
                entityCaptor.capture(),
                eq(String.class));

        String requestBody = entityCaptor.getValue().getBody();
        JsonNode bodyJson = objectMapper.readTree(requestBody);
        assertTrue(bodyJson.has("xy"), "Request body should include xy color values");
        assertTrue(bodyJson.get("xy").isArray(), "xy should be an array");
        assertEquals(2, bodyJson.get("xy").size(), "xy array should have 2 elements");

        // For red (#FF0000), xy values should be approximately [0.701, 0.299]
        // Use small delta for floating point comparisons
        double x = bodyJson.get("xy").get(0).asDouble();
        double y = bodyJson.get("xy").get(1).asDouble();
        assertTrue(Math.abs(x - 0.701) < 0.05, "x value should be close to 0.701 for red");
        assertTrue(Math.abs(y - 0.299) < 0.05, "y value should be close to 0.299 for red");
    }

    @Test
    public void testSetAllLightsColorWithTransition() throws IOException {
        // Mock response
        ResponseEntity<String> mockResponse = mock(ResponseEntity.class);
        when(mockResponse.getStatusCode()).thenReturn(org.springframework.http.HttpStatus.OK);
        when(mockRestTemplate.exchange(anyString(), any(HttpMethod.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(mockResponse);

        // Execute test
        String hexColor = "#00FF00"; // Green
        int transitionTimeDs = 10; // 1 second
        hueBridgeService.setAllLightsColorWithTransition(hexColor, transitionTimeDs);

        // Verify request body
        ArgumentCaptor<HttpEntity<String>> entityCaptor = ArgumentCaptor.forClass(HttpEntity.class);
        verify(mockRestTemplate).exchange(
                anyString(),
                eq(HttpMethod.PUT),
                entityCaptor.capture(),
                eq(String.class));

        String requestBody = entityCaptor.getValue().getBody();
        JsonNode bodyJson = objectMapper.readTree(requestBody);
        assertTrue(bodyJson.has("xy"), "Request body should include xy color values");
        assertTrue(bodyJson.has("transitiontime"), "Request body should include transition time");
        assertEquals(transitionTimeDs, bodyJson.get("transitiontime").asInt(), "Transition time should match");
    }

    @Test
    public void testTestConnectionSuccess() throws Exception {
        // Mock successful bridge response
        String successResponse = "{\"name\":\"Philips hue\", \"swversion\": \"1935144020\"}";
        ResponseEntity<String> mockResponse = mock(ResponseEntity.class);
        when(mockResponse.getStatusCode()).thenReturn(org.springframework.http.HttpStatus.OK);
        when(mockResponse.getBody()).thenReturn(successResponse);
        when(mockRestTemplate.getForEntity(anyString(), eq(String.class))).thenReturn(mockResponse);

        // Execute test
        boolean result = hueBridgeService.testConnection();

        // Verify
        assertTrue(result, "Connection test should succeed");

        // Verify request URL
        ArgumentCaptor<String> urlCaptor = ArgumentCaptor.forClass(String.class);
        verify(mockRestTemplate).getForEntity(urlCaptor.capture(), eq(String.class));

        String expectedUrl = String.format("http://%s/api/%s/config", EXPECTED_BRIDGE_IP, EXPECTED_API_KEY);
        assertEquals(expectedUrl, urlCaptor.getValue(), "Should use correct URL");
    }

    @Test
    public void testTestConnectionFailure() throws Exception {
        // Mock error response
        String errorResponse = "[{\"error\":{\"type\":1,\"address\":\"/\",\"description\":\"unauthorized user\"}}]";
        ResponseEntity<String> mockResponse = mock(ResponseEntity.class);
        when(mockResponse.getStatusCode()).thenReturn(org.springframework.http.HttpStatus.OK);
        when(mockResponse.getBody()).thenReturn(errorResponse);
        when(mockRestTemplate.getForEntity(anyString(), eq(String.class))).thenReturn(mockResponse);

        // Execute test
        boolean result = hueBridgeService.testConnection();

        // Verify
        assertFalse(result, "Connection test should fail with error response");
    }

    @Test
    public void testTestConnectionException() throws Exception {
        // Mock exception
        when(mockRestTemplate.getForEntity(anyString(), eq(String.class)))
                .thenThrow(new RuntimeException("Network error"));

        // Execute test
        boolean result = hueBridgeService.testConnection();

        // Verify
        assertFalse(result, "Connection test should fail with exception");
    }

    @Test
    public void testRgbToXy() throws Exception {
        // Use reflection to access private method
        Method rgbToXyMethod = HueBridgeService.class.getDeclaredMethod("rgbToXy", int.class, int.class, int.class);
        rgbToXyMethod.setAccessible(true);

        // Test with primary colors
        double[] redResult = (double[]) rgbToXyMethod.invoke(hueBridgeService, 255, 0, 0);
        double[] greenResult = (double[]) rgbToXyMethod.invoke(hueBridgeService, 0, 255, 0);
        double[] blueResult = (double[]) rgbToXyMethod.invoke(hueBridgeService, 0, 0, 255);

        // Red should be approximately [0.701, 0.299]
        assertTrue(Math.abs(redResult[0] - 0.701) < 0.05, "x value for red");
        assertTrue(Math.abs(redResult[1] - 0.299) < 0.05, "y value for red");

        // Green should be approximately [0.2, 0.7]
        assertTrue(Math.abs(greenResult[0] - 0.2) < 0.1, "x value for green");
        assertTrue(Math.abs(greenResult[1] - 0.7) < 0.1, "y value for green");

        // Blue should be approximately [0.167, 0.04]
        assertTrue(Math.abs(blueResult[0] - 0.167) < 0.05, "x value for blue");
        assertTrue(Math.abs(blueResult[1] - 0.04) < 0.05, "y value for blue");
    }
}
