package com.soft.p4.controller;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.soft.p4.hueScriptLanguage.interpreter.HueScriptInterpreter;
import com.soft.p4.service.HueBridgeService;

@RestController
@RequestMapping("/api/test")
public class TestController {

    private final HueBridgeService hueBridgeService;
    private final HueScriptInterpreter hueScriptInterpreter;

    @Autowired
    public TestController(HueBridgeService hueBridgeService, HueScriptInterpreter hueScriptInterpreter) {
        this.hueBridgeService = hueBridgeService;
        this.hueScriptInterpreter = hueScriptInterpreter;
    }

    @GetMapping("/lights-on")
    public ResponseEntity<?> turnLightsOn() {
        Map<String, Object> response = new HashMap<>();
        try {
            hueBridgeService.setAllLightsState(true);
            response.put("success", true);
            response.put("message", "All lights turned ON");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.ok(response);
        }
    }

    @GetMapping("/lights-off")
    public ResponseEntity<?> turnLightsOff() {
        Map<String, Object> response = new HashMap<>();
        try {
            hueBridgeService.setAllLightsState(false);
            response.put("success", true);
            response.put("message", "All lights turned OFF");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.ok(response);
        }
    }

    @GetMapping("/emergency-stop")
    public ResponseEntity<?> emergencyStop() {
        Map<String, Object> response = new HashMap<>();
        try {
            // Stop any active script execution
            hueScriptInterpreter.cancel();

            // Reset lights to safe state
            hueBridgeService.setAllLightsState(true);
            hueBridgeService.setAllLightsBrightness(128); // 50% brightness
            hueBridgeService.setAllLightsColor("#FF0000"); // Red for visibility

            response.put("success", true);
            response.put("message", "All scripts stopped and lights reset to standard state");
            return ResponseEntity.ok(response);
        } catch (IOException e) {
            response.put("success", false);
            response.put("error", "Failed to reset lights: " + e.getMessage());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", "Unknown error: " + e.getMessage());
            return ResponseEntity.ok(response);
        }
    }

    @GetMapping("/set-color/{color}")
    public ResponseEntity<?> setColor(@PathVariable String color) {
        Map<String, Object> response = new HashMap<>();
        try {
            String hexColor;
            // Map common color names to hex values
            switch (color.toLowerCase()) {
                case "red":
                    hexColor = "#FF0000";
                    break;
                case "green":
                    hexColor = "#00FF00";
                    break;
                case "blue":
                    hexColor = "#0000FF";
                    break;
                default:
                    hexColor = "#" + color; // Assume hex code without # prefix
            }

            hueBridgeService.setAllLightsColor(hexColor);
            response.put("success", true);
            response.put("message", "Color set to " + hexColor);
            return ResponseEntity.ok(response);
        } catch (IOException e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.ok(response);
        }
    }

    @GetMapping("/set-brightness/{level}")
    public ResponseEntity<?> setBrightness(@PathVariable int level) {
        Map<String, Object> response = new HashMap<>();
        try {
            // Scale brightness from percentage to Hue range (0-254)
            int hueBrightness = (level * 254) / 100;
            hueBridgeService.setAllLightsBrightness(hueBrightness);
            response.put("success", true);
            response.put("message", "Brightness set to " + level + "%");
            return ResponseEntity.ok(response);
        } catch (IOException e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.ok(response);
        }
    }

    @GetMapping("/light/{id}/on")
    public ResponseEntity<?> turnLightOn(@PathVariable String id) {
        Map<String, Object> response = new HashMap<>();
        try {
            hueBridgeService.setLightState(id, true);
            response.put("success", true);
            response.put("message", "Light " + id + " turned ON");
            return ResponseEntity.ok(response);
        } catch (IOException e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.ok(response);
        }
    }

    @GetMapping("/light/{id}/off")
    public ResponseEntity<?> turnLightOff(@PathVariable String id) {
        Map<String, Object> response = new HashMap<>();
        try {
            hueBridgeService.setLightState(id, false);
            response.put("success", true);
            response.put("message", "Light " + id + " turned OFF");
            return ResponseEntity.ok(response);
        } catch (IOException e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.ok(response);
        }
    }

    @GetMapping("/light/{id}/color/{color}")
    public ResponseEntity<?> setLightColor(@PathVariable String id, @PathVariable String color) {
        Map<String, Object> response = new HashMap<>();
        try {
            String hexColor;
            // Map common color names to hex values
            switch (color.toLowerCase()) {
                case "red":
                    hexColor = "#FF0000";
                    break;
                case "green":
                    hexColor = "#00FF00";
                    break;
                case "blue":
                    hexColor = "#0000FF";
                    break;
                default:
                    hexColor = "#" + color; // Assume hex code without # prefix
            }

            hueBridgeService.setLightColor(id, hexColor);
            response.put("success", true);
            response.put("message", "Light " + id + " color set to " + hexColor);
            return ResponseEntity.ok(response);
        } catch (IOException e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.ok(response);
        }
    }

    @GetMapping("/light/{id}/brightness/{level}")
    public ResponseEntity<?> setLightBrightness(@PathVariable String id, @PathVariable int level) {
        Map<String, Object> response = new HashMap<>();
        try {
            // Scale brightness from percentage to Hue range (0-254)
            int hueBrightness = (level * 254) / 100;
            hueBridgeService.setLightBrightness(id, hueBrightness);
            response.put("success", true);
            response.put("message", "Light " + id + " brightness set to " + level + "%");
            return ResponseEntity.ok(response);
        } catch (IOException e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.ok(response);
        }
    }
}
