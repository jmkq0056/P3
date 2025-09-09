package com.soft.p4.service;

import java.io.IOException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * High-level service for Philips Hue light control. Wraps bridge communication
 * and provides simplified light management APIs.
 */
@Service
public class LightService {

    private final HueBridgeService hueBridgeService;

    @Autowired
    public LightService(HueBridgeService hueBridgeService) {
        this.hueBridgeService = hueBridgeService;
    }

    /**
     * Validates bridge connection and auth status
     */
    public boolean testConnection() {
        return hueBridgeService.testConnection();
    }

    /**
     * Controls power state for all lights
     */
    public void setLightsState(boolean on) {
        try {
            hueBridgeService.setAllLightsState(on);
        } catch (IOException e) {
            throw new RuntimeException("Failed to set lights state: " + e.getMessage(), e);
        }
    }

    /**
     * Controls power state for a single light
     */
    public void setLightState(String lightId, boolean on) {
        try {
            hueBridgeService.setLightState(lightId, on);
        } catch (IOException e) {
            throw new RuntimeException("Failed to set light state for light " + lightId + ": " + e.getMessage(), e);
        }
    }

    /**
     * Smoothly transitions all lights between colors. Enforces minimum duration
     * for visual quality.
     *
     * @param fromColorHex Starting color (#RRGGBB)
     * @param toColorHex Target color (#RRGGBB)
     * @param durationMs Min 700ms, clamped if lower
     */
    public void transitionColor(String fromColorHex, String toColorHex, long durationMs) {
        try {
            // Enforce minimum duration
            long actualDurationMs = Math.max(700, durationMs);

            // Set initial color with brief pause
            hueBridgeService.setAllLightsColor(fromColorHex);
            try {
                Thread.sleep(300);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }

            // Convert ms to deciseconds for Hue API
            long remainingDurationMs = actualDurationMs - 300;
            int transitionTimeDs = (int) Math.max(1, Math.round(remainingDurationMs / 100.0));

            // Run transition
            hueBridgeService.setAllLightsColorWithTransition(toColorHex, transitionTimeDs);

            // Wait for completion
            try {
                Thread.sleep(remainingDurationMs);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new RuntimeException("Color transition interrupted");
            }
        } catch (IOException e) {
            throw new RuntimeException("Failed to transition color: " + e.getMessage(), e);
        }
    }

    /**
     * Sets brightness for all lights
     *
     * @param brightness 0-254 (0=off, 254=max)
     */
    public void setBrightness(int brightness) {
        try {
            hueBridgeService.setAllLightsBrightness(brightness);
        } catch (IOException e) {
            throw new RuntimeException("Failed to set brightness: " + e.getMessage(), e);
        }
    }

    /**
     * Sets color for all lights
     *
     * @param colorHex Color in #RRGGBB format
     */
    public void setColor(String colorHex) {
        try {
            hueBridgeService.setAllLightsColor(colorHex);
        } catch (IOException e) {
            throw new RuntimeException("Failed to set color: " + e.getMessage(), e);
        }
    }

    /**
     * Sets color for a single light
     *
     * @param lightId Light identifier
     * @param colorHex Color in #RRGGBB format
     */
    public void setLightColor(String lightId, String colorHex) {
        try {
            hueBridgeService.setLightColor(lightId, colorHex);
        } catch (IOException e) {
            throw new RuntimeException("Failed to set color for light " + lightId + ": " + e.getMessage(), e);
        }
    }

    /**
     * Sets brightness for a single light
     *
     * @param lightId Light identifier
     * @param brightness 0-254 (0=off, 254=max)
     */
    public void setLightBrightness(String lightId, int brightness) {
        try {
            hueBridgeService.setLightBrightness(lightId, brightness);
        } catch (IOException e) {
            throw new RuntimeException("Failed to set brightness for light " + lightId + ": " + e.getMessage(), e);
        }
    }

    /**
     * Smoothly transitions a single light's color. Enforces minimum duration
     * for visual quality.
     *
     * @param lightId Light identifier
     * @param fromColorHex Starting color (#RRGGBB)
     * @param toColorHex Target color (#RRGGBB)
     * @param durationMs Min 700ms, clamped if lower
     */
    public void transitionLightColor(String lightId, String fromColorHex, String toColorHex, long durationMs) {
        try {
            // Enforce minimum duration
            long actualDurationMs = Math.max(700, durationMs);

            // Set initial color with brief pause
            hueBridgeService.setLightColor(lightId, fromColorHex);
            try {
                Thread.sleep(300);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }

            // Convert ms to deciseconds for Hue API
            long remainingDurationMs = actualDurationMs - 300;
            int transitionTimeDs = (int) Math.max(1, Math.round(remainingDurationMs / 100.0));

            // Run transition
            hueBridgeService.setLightColorWithTransition(lightId, toColorHex, transitionTimeDs);

            // Wait for completion
            try {
                Thread.sleep(remainingDurationMs);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new RuntimeException("Color transition interrupted");
            }
        } catch (IOException e) {
            throw new RuntimeException("Failed to transition color for light " + lightId + ": " + e.getMessage(), e);
        }
    }
}
