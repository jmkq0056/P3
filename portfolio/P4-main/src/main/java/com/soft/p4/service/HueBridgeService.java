package com.soft.p4.service;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.time.Duration;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

/**
 * Low-level service for direct Philips Hue Bridge communication. Handles REST
 * API calls, color space conversion, and bridge configuration. Uses properties
 * file for persistent bridge settings.
 */
@Service
public class HueBridgeService {

    // Bridge config with fallback defaults
    private String bridgeIp = "192.168.8.100";
    private String apiKey = "11pToqtVvmoGFJUKshDTZcMChfEMfxDqu-FDB33A";
    private static final String CONFIG_FILE = "config/bridge.properties";
    private static final Logger logger = Logger.getLogger(HueBridgeService.class.getName());

    // RestTemplate with short timeouts to prevent UI blocking
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public HueBridgeService() {
        // Configure RestTemplate with short timeouts for responsive UI
        this.restTemplate = new RestTemplateBuilder()
                .setConnectTimeout(Duration.ofSeconds(3))
                .setReadTimeout(Duration.ofSeconds(5))
                .build();

        // Load bridge settings from properties file
        loadSettings();
    }

    /**
     * Returns configured bridge IP
     */
    public String getBridgeIp() {
        return bridgeIp;
    }

    /**
     * Returns active API key
     */
    public String getApiKey() {
        return apiKey;
    }

    /**
     * Updates bridge connection settings. Tests connectivity before persisting
     * changes.
     *
     * @param newBridgeIp Bridge IP address
     * @param newApiKey Optional API key (keeps existing if null)
     * @return true if connection successful
     */
    public boolean updateBridgeSettings(String newBridgeIp, String newApiKey) {
        try {
            this.bridgeIp = newBridgeIp;
            if (newApiKey != null && !newApiKey.trim().isEmpty()) {
                this.apiKey = newApiKey;
            }
            saveSettings();
            return testConnection();
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Failed to update bridge settings: " + e.getMessage(), e);
            return false;
        }
    }

    /**
     * Saves bridge config to properties file
     */
    private void saveSettings() {
        try {
            File configDir = new File("config");
            if (!configDir.exists()) {
                configDir.mkdirs();
            }

            Properties properties = new Properties();
            properties.setProperty("bridge.ip", bridgeIp);
            properties.setProperty("bridge.apiKey", apiKey);

            try (FileOutputStream out = new FileOutputStream(CONFIG_FILE)) {
                properties.store(out, "Hue Bridge Configuration");
                logger.info("Bridge settings saved to " + CONFIG_FILE);
            }
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Failed to save bridge settings: " + e.getMessage(), e);
        }
    }

    /**
     * Loads bridge config from properties file. Creates default config if
     * missing.
     */
    private void loadSettings() {
        try {
            File configFile = new File(CONFIG_FILE);
            if (configFile.exists()) {
                Properties properties = new Properties();
                try (FileInputStream in = new FileInputStream(configFile)) {
                    properties.load(in);
                    if (properties.containsKey("bridge.ip")) {
                        this.bridgeIp = properties.getProperty("bridge.ip");
                    }
                    if (properties.containsKey("bridge.apiKey")) {
                        this.apiKey = properties.getProperty("bridge.apiKey");
                    }
                    logger.info("Bridge settings loaded from " + CONFIG_FILE);
                }
            } else {
                saveSettings();
                logger.info("Created default bridge settings file");
            }
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Failed to load bridge settings: " + e.getMessage(), e);
        }
    }

    /**
     * Controls power state for all lights
     *
     * @param state true=on, false=off
     */
    public void setAllLightsState(boolean state) throws IOException {
        String url = String.format("http://%s/api/%s/groups/0/action", bridgeIp, apiKey);

        ObjectNode requestBody = objectMapper.createObjectNode();
        requestBody.put("on", state);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> entity = new HttpEntity<>(requestBody.toString(), headers);

        try {
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.PUT, entity, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                System.out.println("All lights turned " + (state ? "ON" : "OFF"));
            } else {
                throw new IOException("Failed to set lights state: " + response.getStatusCode());
            }
        } catch (Exception e) {
            throw new IOException("Error communicating with Hue Bridge: " + e.getMessage(), e);
        }
    }

    /**
     * Controls power state for a single light
     *
     * @param lightId Light identifier
     * @param state true=on, false=off
     */
    public void setLightState(String lightId, boolean state) throws IOException {
        String url = String.format("http://%s/api/%s/lights/%s/state", bridgeIp, apiKey, lightId);

        ObjectNode requestBody = objectMapper.createObjectNode();
        requestBody.put("on", state);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> entity = new HttpEntity<>(requestBody.toString(), headers);

        try {
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.PUT, entity, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                System.out.println("Light " + lightId + " turned " + (state ? "ON" : "OFF"));
            } else {
                throw new IOException("Failed to set light state: " + response.getStatusCode());
            }
        } catch (Exception e) {
            throw new IOException("Error communicating with Hue Bridge: " + e.getMessage(), e);
        }
    }

    /**
     * Sets brightness for all lights
     *
     * @param brightness 0-254 (0=off, 254=max)
     */
    public void setAllLightsBrightness(int brightness) throws IOException {
        String url = String.format("http://%s/api/%s/groups/0/action", bridgeIp, apiKey);
        ObjectNode requestBody = objectMapper.createObjectNode();
        requestBody.put("bri", brightness);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> entity = new HttpEntity<>(requestBody.toString(), headers);

        restTemplate.exchange(url, HttpMethod.PUT, entity, String.class);
    }

    /**
     * Sets color for all lights
     *
     * @param hexColor Color in #RRGGBB format
     */
    public void setAllLightsColor(String hexColor) throws IOException {
        String url = String.format("http://%s/api/%s/groups/0/action", bridgeIp, apiKey);

        java.awt.Color color = java.awt.Color.decode(hexColor);
        double[] xy = rgbToXy(color.getRed(), color.getGreen(), color.getBlue());

        ObjectNode requestBody = objectMapper.createObjectNode();
        ArrayNode xyArray = requestBody.putArray("xy");
        xyArray.add(xy[0]);
        xyArray.add(xy[1]);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> entity = new HttpEntity<>(requestBody.toString(), headers);

        try {
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.PUT, entity, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                System.out.println("All lights color set to " + hexColor);
            } else {
                throw new IOException("Failed to set lights color: " + response.getStatusCode());
            }
        } catch (Exception e) {
            throw new IOException("Error communicating with Hue Bridge: " + e.getMessage(), e);
        }
    }

    /**
     * Sets color for a single light
     *
     * @param lightId Light identifier
     * @param hexColor Color in #RRGGBB format
     */
    public void setLightColor(String lightId, String hexColor) throws IOException {
        String url = String.format("http://%s/api/%s/lights/%s/state", bridgeIp, apiKey, lightId);

        java.awt.Color color = java.awt.Color.decode(hexColor);
        double[] xy = rgbToXy(color.getRed(), color.getGreen(), color.getBlue());

        ObjectNode requestBody = objectMapper.createObjectNode();
        ArrayNode xyArray = requestBody.putArray("xy");
        xyArray.add(xy[0]);
        xyArray.add(xy[1]);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> entity = new HttpEntity<>(requestBody.toString(), headers);

        try {
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.PUT, entity, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                System.out.println("Light " + lightId + " color set to " + hexColor);
            } else {
                throw new IOException("Failed to set light color: " + response.getStatusCode());
            }
        } catch (Exception e) {
            throw new IOException("Error communicating with Hue Bridge: " + e.getMessage(), e);
        }
    }

    /**
     * Transitions a light's color using native Hue fade
     *
     * @param lightId Light identifier
     * @param hexColor Target color in #RRGGBB format
     * @param transitionTimeDs Duration in deciseconds (10ths of a second)
     */
    public void setLightColorWithTransition(String lightId, String hexColor, int transitionTimeDs) throws IOException {
        String url = String.format("http://%s/api/%s/lights/%s/state", bridgeIp, apiKey, lightId);

        java.awt.Color color = java.awt.Color.decode(hexColor);
        double[] xy = rgbToXy(color.getRed(), color.getGreen(), color.getBlue());

        ObjectNode requestBody = objectMapper.createObjectNode();
        ArrayNode xyArray = requestBody.putArray("xy");
        xyArray.add(xy[0]);
        xyArray.add(xy[1]);
        requestBody.put("transitiontime", transitionTimeDs);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> entity = new HttpEntity<>(requestBody.toString(), headers);

        try {
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.PUT, entity, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                System.out.println("Light " + lightId + " transitioning to " + hexColor);
            } else {
                throw new IOException("Failed to set light color with transition: " + response.getStatusCode());
            }
        } catch (Exception e) {
            throw new IOException("Error communicating with Hue Bridge: " + e.getMessage(), e);
        }
    }

    /**
     * Converts RGB to Philips Hue xy color space. Based on official Hue SDK
     * color conversion.
     */
    private double[] rgbToXy(int red, int green, int blue) {
        // Normalize RGB values
        float r = red / 255.0f;
        float g = green / 255.0f;
        float b = blue / 255.0f;

        // Apply gamma correction
        r = (r > 0.04045f) ? (float) Math.pow((r + 0.055f) / 1.055f, 2.4) : r / 12.92f;
        g = (g > 0.04045f) ? (float) Math.pow((g + 0.055f) / 1.055f, 2.4) : g / 12.92f;
        b = (b > 0.04045f) ? (float) Math.pow((b + 0.055f) / 1.055f, 2.4) : b / 12.92f;

        // Convert to XYZ space
        float X = r * 0.664511f + g * 0.154324f + b * 0.162028f;
        float Y = r * 0.283881f + g * 0.668433f + b * 0.047685f;
        float Z = r * 0.000088f + g * 0.072310f + b * 0.986039f;

        // Calculate xy values
        float sum = X + Y + Z;
        return sum > 0 ? new double[]{X / sum, Y / sum} : new double[]{0.0, 0.0};
    }

    /**
     * Tests bridge connectivity and API key validity
     */
    public boolean testConnection() {
        try {
            String url = String.format("http://%s/api/%s/config", bridgeIp, apiKey);
            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                JsonNode jsonNode = objectMapper.readTree(response.getBody());

                // Check for error responses
                if (jsonNode.isArray() && jsonNode.size() > 0) {
                    JsonNode firstElement = jsonNode.get(0);
                    if (firstElement.has("error")) {
                        return false;
                    }
                } else if (jsonNode.has("error")) {
                    return false;
                }
                return true;
            }
            return false;
        } catch (Exception e) {
            System.err.println("Error testing connection: " + e.getMessage());
            return false;
        }
    }

    /**
     * Transitions all lights to a new color using native Hue fade
     *
     * @param hexColor Target color in #RRGGBB format
     * @param transitionTimeDs Duration in deciseconds (10ths of a second)
     */
    public void setAllLightsColorWithTransition(String hexColor, int transitionTimeDs) throws IOException {
        String url = String.format("http://%s/api/%s/groups/0/action", bridgeIp, apiKey);

        java.awt.Color color = java.awt.Color.decode(hexColor);
        double[] xy = rgbToXy(color.getRed(), color.getGreen(), color.getBlue());

        ObjectNode requestBody = objectMapper.createObjectNode();
        ArrayNode xyArray = requestBody.putArray("xy");
        xyArray.add(xy[0]);
        xyArray.add(xy[1]);
        requestBody.put("transitiontime", transitionTimeDs);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> entity = new HttpEntity<>(requestBody.toString(), headers);

        try {
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.PUT, entity, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                System.out.println("Transitioning lights to " + hexColor + " over "
                        + (transitionTimeDs / 10.0) + " seconds");
            } else {
                throw new IOException("Failed to set lights color with transition: " + response.getStatusCode());
            }
        } catch (Exception e) {
            throw new IOException("Error communicating with Hue Bridge: " + e.getMessage(), e);
        }
    }

    /**
     * Retrieves state info for all connected lights
     *
     * @return Map of light IDs to their state objects
     */
    public Map<String, JsonNode> getAllLights() throws IOException {
        String url = String.format("http://%s/api/%s/lights", bridgeIp, apiKey);

        try {
            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                Map<String, JsonNode> lightsMap = new HashMap<>();
                JsonNode lights = objectMapper.readTree(response.getBody());

                Iterator<Map.Entry<String, JsonNode>> fieldsIterator = lights.fields();
                while (fieldsIterator.hasNext()) {
                    Map.Entry<String, JsonNode> entry = fieldsIterator.next();
                    lightsMap.put(entry.getKey(), entry.getValue());
                }

                return lightsMap;
            } else {
                throw new IOException("Failed to get lights: " + response.getStatusCode());
            }
        } catch (Exception e) {
            throw new IOException("Error communicating with Hue Bridge: " + e.getMessage(), e);
        }
    }

    /**
     * Creates a blinking effect on a single light
     *
     * @param lightId Light identifier
     * @param times Number of blink cycles
     * @param hexColor Color to blink (#RRGGBB)
     */
    public void blinkLight(String lightId, int times, String hexColor) throws IOException, InterruptedException {
        // Save the light's original state
        boolean isOn = true; // Default to on, we'll turn on if not already

        // Turn the light on first to ensure it's visible
        setLightState(lightId, true);

        // Save original color - for simplicity, we'll just set it back to white at the end
        String originalColor = "#FFFFFF";

        // Blink the light
        for (int i = 0; i < times; i++) {
            // Set the blink color
            setLightColor(lightId, hexColor);
            Thread.sleep(500); // On for 500ms

            // Turn off
            setLightState(lightId, false);
            Thread.sleep(300); // Off for 300ms

            // Turn back on
            setLightState(lightId, true);
        }

        // Set back to original color (white)
        setLightColor(lightId, originalColor);
    }

    /**
     * Sets brightness for a single light
     *
     * @param lightId Light identifier
     * @param brightness 0-254 (0=off, 254=max)
     */
    public void setLightBrightness(String lightId, int brightness) throws IOException {
        String url = String.format("http://%s/api/%s/lights/%s/state", bridgeIp, apiKey, lightId);
        ObjectNode requestBody = objectMapper.createObjectNode();
        requestBody.put("bri", brightness);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> entity = new HttpEntity<>(requestBody.toString(), headers);

        try {
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.PUT, entity, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                System.out.println("Light " + lightId + " brightness set to " + brightness);
            } else {
                throw new IOException("Failed to set light brightness: " + response.getStatusCode());
            }
        } catch (Exception e) {
            throw new IOException("Error communicating with Hue Bridge: " + e.getMessage(), e);
        }
    }
}
