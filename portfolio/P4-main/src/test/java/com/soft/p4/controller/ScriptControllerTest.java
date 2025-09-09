package com.soft.p4.controller;

import java.util.HashMap;
import java.util.Map;

import static org.hamcrest.Matchers.containsString;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import org.springframework.web.context.WebApplicationContext;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.soft.p4.hueScriptLanguage.interpreter.HueScriptInterpreter;
import com.soft.p4.service.HueBridgeService;
import com.soft.p4.service.LightService;

/**
 * Test suite for ScriptController REST endpoints. Validates script execution,
 * connection testing, and state management.
 */
@WebMvcTest(ScriptController.class)
public class ScriptControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private HueScriptInterpreter mockInterpreter;

    @MockBean
    private HueBridgeService mockHueBridgeService;

    @MockBean
    private LightService mockLightService;

    @MockBean
    private WebApplicationContext mockApplicationContext;

    @BeforeEach
    public void setUp() {
        when(mockApplicationContext.getBean(LightService.class)).thenReturn(mockLightService);
    }

    @Test
    public void testExecuteScriptSuccess() throws Exception {
        // Prepare test data
        String script = "lights on; wait 2 sec; lights off;";
        String logOutput = "💡 Turning all lights ON...\n⏱️ Waiting for 2 seconds...\n💡 Turning all lights OFF...\n✅ Script execution completed successfully\n";

        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("scriptContent", script);

        // Mock dependencies
        when(mockHueBridgeService.testConnection()).thenReturn(true);
        when(mockInterpreter.executeScript(script, true)).thenReturn(logOutput);

        mockMvc.perform(post("/api/scripts/execute")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.log").value(logOutput))
                .andExpect(jsonPath("$.success").value(true));

        verify(mockInterpreter).executeScript(script, true);
    }

    @Test
    public void testExecuteScriptWithError() throws Exception {
        // Prepare test data
        String script = "lights onn;"; // Invalid script
        String logOutput = "❌ Execution error: Unexpected token: on at line 1\n";

        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("scriptContent", script);

        // Mock dependencies
        when(mockHueBridgeService.testConnection()).thenReturn(true);
        when(mockInterpreter.executeScript(script, true)).thenReturn(logOutput);

        mockMvc.perform(post("/api/scripts/execute")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.log").value(logOutput))
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    public void testExecuteScriptBridgeDisconnected() throws Exception {
        // Prepare test data
        String script = "lights on;";

        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("scriptContent", script);

        // Mock bridge disconnected
        when(mockHueBridgeService.testConnection()).thenReturn(false);

        mockMvc.perform(post("/api/scripts/execute")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.log").value(containsString("❌ Hue Bridge connection failed")))
                .andExpect(jsonPath("$.success").value(false));

        // Verify interpreter never called
        verify(mockInterpreter, never()).executeScript(anyString());
    }

    @Test
    public void testExecuteEmptyScript() throws Exception {
        // Prepare test data
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("scriptContent", "");

        // Mock dependencies
        when(mockHueBridgeService.testConnection()).thenReturn(true);

        mockMvc.perform(post("/api/scripts/execute")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void testResetState() throws Exception {
        // Mock dependencies
        when(mockApplicationContext.getBean(LightService.class)).thenReturn(mockLightService);

        mockMvc.perform(post("/api/scripts/reset-state"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Interpreter state reset successfully"));
    }

    @Test
    public void testTestConnection() throws Exception {
        // Mock successful connection
        when(mockHueBridgeService.testConnection()).thenReturn(true);

        mockMvc.perform(get("/api/scripts/test-connection"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.connected").value(true))
                .andExpect(jsonPath("$.bridgeIp").value("192.168.8.100"));
    }

    @Test
    public void testTestConnectionFailed() throws Exception {
        // Mock failed connection
        when(mockHueBridgeService.testConnection()).thenReturn(false);

        mockMvc.perform(get("/api/scripts/test-connection"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.connected").value(false))
                .andExpect(jsonPath("$.message").value(containsString("Failed to connect to Hue Bridge")));
    }

    @Test
    public void testExecuteComplexScriptWithGroupsAndScenes() throws Exception {
        // Prepare test data for complex script with groups and scenes
        String script
                = "group \"living\" = [\"1\", \"2\", \"3\"];\n"
                + "group \"bedroom\" = [\"4\", \"5\"];\n"
                + "define scene movieScene {\n"
                + "  group \"living\" brightness 20;\n"
                + "  group \"living\" color \"blue\";\n"
                + "  group \"bedroom\" off;\n"
                + "}\n"
                + "scene movieScene;";

        String logOutput = "👥 Group 'living' defined with 3 lights: 1, 2, 3\n"
                + "👥 Group 'bedroom' defined with 2 lights: 4, 5\n"
                + "📋 Scene 'movieScene' defined with 3 commands\n"
                + "📋 Invoking scene 'movieScene'\n"
                + "👥 Setting brightness of 3 lights in group 'living' to 20%...\n"
                + "✅ Group brightness command completed\n"
                + "👥 Setting color of 3 lights in group 'living' to #0000FF...\n"
                + "✅ Group color command completed\n"
                + "👥 Setting 2 lights in group 'bedroom' to OFF...\n"
                + "✅ Group light command completed\n"
                + "✅ Script execution completed successfully\n";

        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("scriptContent", script);

        // Mock dependencies
        when(mockHueBridgeService.testConnection()).thenReturn(true);
        when(mockInterpreter.executeScript(script, true)).thenReturn(logOutput);

        mockMvc.perform(post("/api/scripts/execute")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.log").value(logOutput))
                .andExpect(jsonPath("$.success").value(true));

        verify(mockInterpreter).executeScript(script, true);
    }

    @Test
    public void testExecuteScriptWithVariablesAndTransitions() throws Exception {
        // Prepare test data
        String script
                = "var warm = \"#FF9900\";\n"
                + "var cool = \"#66CCFF\";\n"
                + "var transitionTime = 5;\n"
                + "transition warm to cool over transitionTime sec;";

        String logOutput = "📝 Variable 'warm' defined with value '#FF9900'\n"
                + "📝 Variable 'cool' defined with value '#66CCFF'\n"
                + "📝 Variable 'transitionTime' defined with value '5'\n"
                + "🌈 Transitioning from #FF9900 to #66CCFF over 5 seconds...\n"
                + "✅ Transition completed\n"
                + "✅ Script execution completed successfully\n";

        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("scriptContent", script);

        // Mock dependencies
        when(mockHueBridgeService.testConnection()).thenReturn(true);
        when(mockInterpreter.executeScript(script, true)).thenReturn(logOutput);

        mockMvc.perform(post("/api/scripts/execute")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.log").value(logOutput))
                .andExpect(jsonPath("$.success").value(true));

        verify(mockInterpreter).executeScript(script, true);
    }

    @Test
    public void testExecuteNestedLoopScript() throws Exception {
        // Prepare test data for script with nested loops
        String script
                = "repeat 3 times {\n"
                + "  lights color \"red\";\n"
                + "  wait 500 ms;\n"
                + "  repeat 2 times {\n"
                + "    lights off;\n"
                + "    wait 200 ms;\n"
                + "    lights on;\n"
                + "    wait 200 ms;\n"
                + "  }\n"
                + "}";

        String logOutput = "🔄 Starting repeat block (3 times)\n"
                + "🎨 Setting all lights color to #FF0000\n"
                + "⏱️ Waiting for 500 ms...\n"
                + "🔄 Starting repeat block (2 times)\n"
                + "💡 Turning all lights OFF...\n"
                + "⏱️ Waiting for 200 ms...\n"
                + "💡 Turning all lights ON...\n"
                + "⏱️ Waiting for 200 ms...\n"
                + "✅ Repeat block completed\n"
                + "✅ Repeat block completed\n"
                + "✅ Script execution completed successfully\n";

        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("scriptContent", script);

        // Mock dependencies
        when(mockHueBridgeService.testConnection()).thenReturn(true);
        when(mockInterpreter.executeScript(script, true)).thenReturn(logOutput);

        mockMvc.perform(post("/api/scripts/execute")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.log").value(logOutput))
                .andExpect(jsonPath("$.success").value(true));

        verify(mockInterpreter).executeScript(script, true);
    }
}
