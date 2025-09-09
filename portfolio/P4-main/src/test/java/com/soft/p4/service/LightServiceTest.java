package com.soft.p4.service;

import java.io.IOException;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import org.mockito.InOrder;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Test suite for LightService functionality. Validates light control operations
 * and bridge service integration.
 */
public class LightServiceTest {

    private LightService lightService;
    private HueBridgeService mockHueBridgeService;

    @BeforeEach
    public void setUp() {
        mockHueBridgeService = mock(HueBridgeService.class);
        lightService = new LightService(mockHueBridgeService);
    }

    @Test
    public void testSetLightsStateOn() throws IOException {
        lightService.setLightsState(true);
        verify(mockHueBridgeService).setAllLightsState(true);
    }

    @Test
    public void testSetLightsStateOff() throws IOException {
        lightService.setLightsState(false);
        verify(mockHueBridgeService).setAllLightsState(false);
    }

    @Test
    public void testSetLightsStateWithException() throws IOException {
        doThrow(new IOException("Bridge communication error"))
                .when(mockHueBridgeService).setAllLightsState(true);

        assertThrows(RuntimeException.class, () -> lightService.setLightsState(true),
                "Should throw RuntimeException when bridge throws IOException");
    }

    @Test
    public void testSetLightState() throws IOException {
        String lightId = "light1";
        lightService.setLightState(lightId, true);
        verify(mockHueBridgeService).setLightState(lightId, true);
    }

    @Test
    public void testSetBrightness() throws IOException {
        lightService.setBrightness(200);
        verify(mockHueBridgeService).setAllLightsBrightness(200);
    }

    @Test
    public void testSetColor() throws IOException {
        String colorHex = "#FF0000";
        lightService.setColor(colorHex);
        verify(mockHueBridgeService).setAllLightsColor(colorHex);
    }

    @Test
    public void testTransitionColor() throws IOException {
        lightService.transitionColor("#FF0000", "#0000FF", 2000);

        // Verify sequence of calls
        InOrder inOrder = inOrder(mockHueBridgeService);

        // First sets the initial color
        inOrder.verify(mockHueBridgeService).setAllLightsColor("#FF0000");

        // Then uses transition to target color
        // Conversion from ms to deciseconds: (2000-300)/100 = 17 ds
        inOrder.verify(mockHueBridgeService).setAllLightsColorWithTransition(eq("#0000FF"), anyInt());
    }

    @Test
    public void testSetLightBrightness() throws IOException {
        String lightId = "light2";
        int brightness = 150;

        lightService.setLightBrightness(lightId, brightness);

        verify(mockHueBridgeService).setLightBrightness(lightId, brightness);
    }

    @Test
    public void testSetLightBrightnessWithException() throws IOException {
        String lightId = "light2";
        int brightness = 150;

        doThrow(new IOException("Bridge communication error"))
                .when(mockHueBridgeService).setLightBrightness(eq(lightId), anyInt());

        assertThrows(RuntimeException.class,
                () -> lightService.setLightBrightness(lightId, brightness),
                "Should throw RuntimeException when bridge throws IOException");
    }

    @Test
    public void testSetLightColor() throws IOException {
        String lightId = "light3";
        String colorHex = "#00FF00";

        lightService.setLightColor(lightId, colorHex);

        verify(mockHueBridgeService).setLightColor(lightId, colorHex);
    }

    @Test
    public void testSetLightColorWithException() throws IOException {
        String lightId = "light3";
        String colorHex = "#00FF00";

        doThrow(new IOException("Bridge communication error"))
                .when(mockHueBridgeService).setLightColor(eq(lightId), anyString());

        assertThrows(RuntimeException.class,
                () -> lightService.setLightColor(lightId, colorHex),
                "Should throw RuntimeException when bridge throws IOException");
    }

    @Test
    public void testTransitionLightColor() throws IOException {
        String lightId = "light4";
        String fromColor = "#FF0000";
        String toColor = "#0000FF";
        long duration = 1500;

        lightService.transitionLightColor(lightId, fromColor, toColor, duration);

        // Verify sequence of calls
        InOrder inOrder = inOrder(mockHueBridgeService);

        // First sets the initial color
        inOrder.verify(mockHueBridgeService).setLightColor(lightId, fromColor);

        // Then uses transition to target color
        inOrder.verify(mockHueBridgeService).setLightColorWithTransition(
                eq(lightId), eq(toColor), anyInt());
    }

    @Test
    public void testTransitionLightColorWithException() throws IOException {
        String lightId = "light4";
        String fromColor = "#FF0000";
        String toColor = "#0000FF";
        long duration = 1500;

        doThrow(new IOException("Bridge communication error"))
                .when(mockHueBridgeService).setLightColorWithTransition(
                eq(lightId), anyString(), anyInt());

        assertThrows(RuntimeException.class,
                () -> lightService.transitionLightColor(lightId, fromColor, toColor, duration),
                "Should throw RuntimeException when bridge throws IOException");
    }

    @Test
    public void testBridgeConnectionStatus() throws IOException {
        when(mockHueBridgeService.testConnection()).thenReturn(true);

        boolean result = lightService.testConnection();

        assertTrue(result, "Connection test should return true when bridge is connected");
        verify(mockHueBridgeService).testConnection();
    }

    @Test
    public void testBridgeConnectionFailure() throws IOException {
        when(mockHueBridgeService.testConnection()).thenReturn(false);

        boolean result = lightService.testConnection();

        assertFalse(result, "Connection test should return false when bridge is disconnected");
        verify(mockHueBridgeService).testConnection();
    }

    @Test
    public void testBridgeConnectionWithException() {
        // testConnection method uses try-catch internally and returns false on exceptions
        when(mockHueBridgeService.testConnection()).thenReturn(false);

        boolean result = lightService.testConnection();

        assertFalse(result, "Connection test should return false when exception occurs");
        verify(mockHueBridgeService).testConnection();
    }
}
