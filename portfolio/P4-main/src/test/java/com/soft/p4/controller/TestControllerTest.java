package com.soft.p4.controller;

import java.io.IOException;

import static org.hamcrest.Matchers.containsString;
import org.junit.jupiter.api.Test;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.soft.p4.hueScriptLanguage.interpreter.HueScriptInterpreter;
import com.soft.p4.service.HueBridgeService;
import com.soft.p4.service.LightService;

/**
 * Test suite for TestController REST endpoints. Validates light control
 * operations and error handling.
 */
@WebMvcTest(TestController.class)
public class TestControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private HueBridgeService mockHueBridgeService;

    @MockBean
    private LightService mockLightService;

    @MockBean
    private HueScriptInterpreter mockInterpreter;

    @Test
    public void testTurnLightsOn() throws Exception {
        // Mock successful lights on
        doNothing().when(mockHueBridgeService).setAllLightsState(true);

        mockMvc.perform(get("/api/test/lights-on"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("All lights turned ON"));

        verify(mockHueBridgeService).setAllLightsState(true);
    }

    @Test
    public void testTurnLightsOnWithError() throws Exception {
        // Mock exception from bridge service
        doThrow(new IOException("Bridge error")).when(mockHueBridgeService).setAllLightsState(true);

        mockMvc.perform(get("/api/test/lights-on"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("Bridge error"));
    }

    @Test
    public void testTurnLightsOff() throws Exception {
        // Mock successful lights off
        doNothing().when(mockHueBridgeService).setAllLightsState(false);

        mockMvc.perform(get("/api/test/lights-off"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("All lights turned OFF"));

        verify(mockHueBridgeService).setAllLightsState(false);
    }

    @Test
    public void testTurnLightsOffWithError() throws Exception {
        // Mock exception from bridge service
        doThrow(new IOException("Bridge error")).when(mockHueBridgeService).setAllLightsState(false);

        mockMvc.perform(get("/api/test/lights-off"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("Bridge error"));
    }

    @Test
    public void testEmergencyStop() throws Exception {
        // Mock successful execution
        doNothing().when(mockHueBridgeService).setAllLightsState(true);
        doNothing().when(mockHueBridgeService).setAllLightsBrightness(128);
        doNothing().when(mockHueBridgeService).setAllLightsColor("#FF0000");
        doNothing().when(mockInterpreter).cancel();

        mockMvc.perform(get("/api/test/emergency-stop"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value(containsString("All scripts stopped")));

        // Verify emergency stop sequence
        verify(mockInterpreter).cancel();
        verify(mockHueBridgeService).setAllLightsState(true);
        verify(mockHueBridgeService).setAllLightsBrightness(128);
        verify(mockHueBridgeService).setAllLightsColor("#FF0000");
    }

    @Test
    public void testEmergencyStopWithError() throws Exception {
        // Mock exception from bridge service
        doNothing().when(mockInterpreter).cancel();
        doThrow(new IOException("Bridge error")).when(mockHueBridgeService).setAllLightsState(true);

        mockMvc.perform(get("/api/test/emergency-stop"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value(containsString("Failed to reset lights")));

        verify(mockInterpreter).cancel();
    }

    @Test
    public void testSetLightColor() throws Exception {
        // Mock successful color setting
        doNothing().when(mockHueBridgeService).setAllLightsColor("#FF0000");

        mockMvc.perform(get("/api/test/set-color/red"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Color set to #FF0000"));

        verify(mockHueBridgeService).setAllLightsColor("#FF0000");
    }

    @Test
    public void testSetLightColorWithError() throws Exception {
        // Mock exception from bridge service
        doThrow(new IOException("Bridge error")).when(mockHueBridgeService).setAllLightsColor(anyString());

        mockMvc.perform(get("/api/test/set-color/blue"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("Bridge error"));
    }

    @Test
    public void testSetLightBrightness() throws Exception {
        // Mock successful brightness setting
        doNothing().when(mockHueBridgeService).setAllLightsBrightness(127);

        mockMvc.perform(get("/api/test/set-brightness/50"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Brightness set to 50%"));

        verify(mockHueBridgeService).setAllLightsBrightness(127);
    }

    @Test
    public void testSetLightBrightnessWithError() throws Exception {
        // Mock exception from bridge service
        doThrow(new IOException("Bridge error")).when(mockHueBridgeService).setAllLightsBrightness(anyInt());

        mockMvc.perform(get("/api/test/set-brightness/75"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("Bridge error"));
    }

    @Test
    public void testSetSingleLightState() throws Exception {
        // Mock successful light control
        doNothing().when(mockHueBridgeService).setLightState("1", true);

        mockMvc.perform(get("/api/test/light/1/on"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Light 1 turned ON"));

        verify(mockHueBridgeService).setLightState("1", true);
    }

    @Test
    public void testSetSingleLightStateWithError() throws Exception {
        // Mock exception from bridge service
        doThrow(new IOException("Bridge error")).when(mockHueBridgeService).setLightState(anyString(), anyBoolean());

        mockMvc.perform(get("/api/test/light/2/off"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("Bridge error"));
    }

    @Test
    public void testSetSingleLightColor() throws Exception {
        // Mock successful color setting for specific light
        doNothing().when(mockHueBridgeService).setLightColor("3", "#00FF00");

        mockMvc.perform(get("/api/test/light/3/color/green"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Light 3 color set to #00FF00"));

        verify(mockHueBridgeService).setLightColor("3", "#00FF00");
    }

    @Test
    public void testSetSingleLightBrightness() throws Exception {
        // Mock successful brightness setting for specific light
        doNothing().when(mockHueBridgeService).setLightBrightness("4", 203);

        mockMvc.perform(get("/api/test/light/4/brightness/80"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Light 4 brightness set to 80%"));

        verify(mockHueBridgeService).setLightBrightness("4", 203);
    }
}
