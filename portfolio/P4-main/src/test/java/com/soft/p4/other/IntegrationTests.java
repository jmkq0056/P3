package com.soft.p4.other;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import static org.hamcrest.Matchers.containsString;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.verify;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.soft.p4.service.HueBridgeService;

/**
 * Integration test suite for end-to-end application functionality. Tests
 * complete workflows including script execution, error handling, and state
 * management.
 */
@SpringBootTest
@AutoConfigureMockMvc
public class IntegrationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private HueBridgeService mockHueBridgeService;

    @Test
    public void testEndToEndScriptExecution() throws Exception {
        // Mock bridge connection check
        Mockito.when(mockHueBridgeService.testConnection()).thenReturn(true);

        // Mock bridge service methods to avoid exceptions
        Mockito.doNothing().when(mockHueBridgeService).setAllLightsState(Mockito.anyBoolean());
        Mockito.doNothing().when(mockHueBridgeService).setAllLightsBrightness(Mockito.anyInt());
        Mockito.doNothing().when(mockHueBridgeService).setAllLightsColor(Mockito.anyString());
        Mockito.doNothing().when(mockHueBridgeService).setAllLightsColorWithTransition(Mockito.anyString(), Mockito.anyInt());

        // Prepare test script
        String script = "// Test script\n"
                + "lights on;\n"
                + "brightness 75;\n"
                + "lights color \"red\";\n"
                + "wait 10 ms;\n"
                + // Use short wait for fast test
                "lights off;";

        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("scriptContent", script);

        // Execute script and verify response
        mockMvc.perform(post("/api/scripts/execute")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.log").value(containsString("💡 Turning all lights ON")))
                .andExpect(jsonPath("$.log").value(containsString("💡 Setting brightness to 75%")))
                .andExpect(jsonPath("$.log").value(containsString("🎨 Setting all lights color to #FF0000")))
                .andExpect(jsonPath("$.log").value(containsString("✅ Script execution completed successfully")));

        // Verify bridge service calls
        Mockito.verify(mockHueBridgeService, atLeastOnce()).setAllLightsState(true);
        Mockito.verify(mockHueBridgeService).setAllLightsBrightness(190); // 75% of 254
        Mockito.verify(mockHueBridgeService).setAllLightsColor("#FF0000");
        Mockito.verify(mockHueBridgeService, atLeastOnce()).setAllLightsState(false);
    }

    @Test
    public void testScriptWithErrorHandling() throws Exception {
        // Mock bridge connection check
        Mockito.when(mockHueBridgeService.testConnection()).thenReturn(true);

        // Make bridge service throw exception for specific method
        Mockito.doThrow(new IOException("Bridge communication error"))
                .when(mockHueBridgeService).setAllLightsColor(Mockito.anyString());

        // Other methods don't throw
        Mockito.doNothing().when(mockHueBridgeService).setAllLightsState(Mockito.anyBoolean());

        // Script that will encounter an error
        String script = "lights on;\n"
                + "lights color \"red\";\n"
                + // This will cause an error
                "lights off;";

        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("scriptContent", script);

        // Execute script and verify error handling
        mockMvc.perform(post("/api/scripts/execute")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.log").value(containsString("💡 Turning all lights ON")))
                .andExpect(jsonPath("$.log").value(containsString("🎨 Setting all lights color to #FF0000")))
                .andExpect(jsonPath("$.log").value(containsString("❌ Execution error")))
                .andExpect(jsonPath("$.log").value(containsString("Bridge communication error")));

        // Verify bridge service calls
        Mockito.verify(mockHueBridgeService, atLeastOnce()).setAllLightsState(true);
        Mockito.verify(mockHueBridgeService, atLeastOnce()).setAllLightsColor("#FF0000");
        // Light off should not be called due to error
        Mockito.verify(mockHueBridgeService, Mockito.never()).setAllLightsState(false);
    }

    @Test
    public void testScriptWithVariablesAndScenes() throws Exception {
        // Mock bridge connection check
        Mockito.when(mockHueBridgeService.testConnection()).thenReturn(true);

        // Mock bridge methods
        Mockito.doNothing().when(mockHueBridgeService).setAllLightsState(Mockito.anyBoolean());
        Mockito.doNothing().when(mockHueBridgeService).setAllLightsBrightness(Mockito.anyInt());
        Mockito.doNothing().when(mockHueBridgeService).setAllLightsColor(Mockito.anyString());

        // Test script with variables and scenes
        String defineScript = "// Define variables and scenes\n"
                + "var myColor = \"blue\";\n"
                + "define scene myScene {\n"
                + "  lights color myColor;\n"
                + "  brightness 50;\n"
                + "}\n"
                + "scene myScene;";

        Map<String, String> defineRequestBody = new HashMap<>();
        defineRequestBody.put("scriptContent", defineScript);

        // Execute definition script with scene invocation
        mockMvc.perform(post("/api/scripts/execute")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(defineRequestBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    public void testResetStateEndpoint() throws Exception {
        // Mock bridge connection check
        Mockito.when(mockHueBridgeService.testConnection()).thenReturn(true);

        // First define a variable and scene
        String defineScript = "var testVar = \"red\";\n"
                + "define scene testScene {\n"
                + "  lights color testVar;\n"
                + "}";

        Map<String, String> defineRequestBody = new HashMap<>();
        defineRequestBody.put("scriptContent", defineScript);

        mockMvc.perform(post("/api/scripts/execute")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(defineRequestBody)))
                .andExpect(status().isOk());

        // Call reset state
        mockMvc.perform(post("/api/scripts/reset-state"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Interpreter state reset successfully"));

        // After reset, variable and scene should no longer be defined
        String useScript = "scene testScene;"; // Try to use the scene that should now be undefined

        Map<String, String> useRequestBody = new HashMap<>();
        useRequestBody.put("scriptContent", useScript);

        mockMvc.perform(post("/api/scripts/execute")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(useRequestBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.log").value(containsString("❌ Execution error")))
                .andExpect(jsonPath("$.log").value(containsString("Undefined scene")));
    }

    @Test
    public void testEmergencyStopEndpoint() throws Exception {
        // Mock bridge connection check
        Mockito.when(mockHueBridgeService.testConnection()).thenReturn(true);

        // Mock bridge service methods
        Mockito.doNothing().when(mockHueBridgeService).setAllLightsState(Mockito.anyBoolean());
        Mockito.doNothing().when(mockHueBridgeService).setAllLightsColor(Mockito.anyString());
        Mockito.doNothing().when(mockHueBridgeService).setAllLightsBrightness(Mockito.anyInt());

        // Call emergency stop endpoint
        mockMvc.perform(get("/api/test/emergency-stop"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("All scripts stopped and lights reset to standard state"));

        // Verify interactions - expect multiple calls due to feedback mechanism
        verify(mockHueBridgeService, atLeastOnce()).setAllLightsState(true);
    }

    @Test
    public void testDirectLightControls() throws Exception {
        // Mock bridge methods
        Mockito.doNothing().when(mockHueBridgeService).setAllLightsState(Mockito.anyBoolean());

        // Test turn on lights endpoint
        mockMvc.perform(get("/api/test/lights-on"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("All lights turned ON"));

        Mockito.verify(mockHueBridgeService).setAllLightsState(true);

        // Reset mock
        Mockito.reset(mockHueBridgeService);
        Mockito.doNothing().when(mockHueBridgeService).setAllLightsState(Mockito.anyBoolean());

        // Test turn off lights endpoint
        mockMvc.perform(get("/api/test/lights-off"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("All lights turned OFF"));

        Mockito.verify(mockHueBridgeService).setAllLightsState(false);
    }

    @Test
    public void testConnectionStatus() throws Exception {
        // Test connected state
        Mockito.when(mockHueBridgeService.testConnection()).thenReturn(true);

        mockMvc.perform(get("/api/scripts/test-connection"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.connected").value(true))
                .andExpect(jsonPath("$.bridgeIp").value("REMOVED_FOR_SECURITY"))
                .andExpect(jsonPath("$.message").value(containsString("Successfully connected")));

        // Test disconnected state
        Mockito.when(mockHueBridgeService.testConnection()).thenReturn(false);

        mockMvc.perform(get("/api/scripts/test-connection"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.connected").value(false))
                .andExpect(jsonPath("$.message").value(containsString("Failed to connect")));
    }
}
