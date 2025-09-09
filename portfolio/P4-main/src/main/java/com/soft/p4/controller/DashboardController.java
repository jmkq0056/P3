package com.soft.p4.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

import com.soft.p4.hueScriptLanguage.interpreter.HueScriptInterpreter;
import com.soft.p4.service.HueBridgeService;
import com.soft.p4.service.LightService;

@Controller
public class DashboardController {

    private final HueBridgeService hueBridgeService;
    private final HueScriptInterpreter hueScriptInterpreter;
    private final LightService lightService;

    @Autowired
    public DashboardController(HueBridgeService hueBridgeService,
            HueScriptInterpreter hueScriptInterpreter,
            LightService lightService) {
        this.hueBridgeService = hueBridgeService;
        this.hueScriptInterpreter = hueScriptInterpreter;
        this.lightService = lightService;
    }

    @GetMapping("/dashboard")
    public String dashboard(Model model) {
        // Load dashboard immediately without blocking on bridge connectivity
        // JavaScript will handle async status updates after page load

        // Populate model with bridge config (always available)
        model.addAttribute("bridgeIp", hueBridgeService.getBridgeIp());
        model.addAttribute("apiKey", hueBridgeService.getApiKey());

        // Use default/cached values for initial render
        // These will be updated by JavaScript once page loads
        model.addAttribute("connected", false); // Will be updated async
        model.addAttribute("lastColor", hueScriptInterpreter.getLastKnownColor());
        model.addAttribute("lastBrightness", hueScriptInterpreter.getLastKnownBrightness());
        model.addAttribute("lightsOn", hueScriptInterpreter.getLastKnownLightState());

        return "dashboard";
    }

    @PostMapping("/api/dashboard/lights/state")
    @ResponseBody
    public ResponseEntity<?> setLightState(@RequestBody Map<String, Object> request) {
        Map<String, Object> response = new HashMap<>();

        try {
            boolean state = (boolean) request.get("state");
            lightService.setLightsState(state);

            // Update interpreter state to reflect the new light state
            hueScriptInterpreter.updateLastKnownLightState(state);

            response.put("success", true);
            response.put("message", "Lights " + (state ? "turned ON" : "turned OFF"));
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.ok(response);
        }
    }

    @PostMapping("/api/dashboard/lights/color")
    @ResponseBody
    public ResponseEntity<?> setLightColor(@RequestBody Map<String, Object> request) {
        Map<String, Object> response = new HashMap<>();

        try {
            String color = (String) request.get("color");
            lightService.setColor(color);

            // Update interpreter state to reflect the new color
            hueScriptInterpreter.updateLastKnownColor(color);

            response.put("success", true);
            response.put("message", "Color set to " + color);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.ok(response);
        }
    }

    @PostMapping("/api/dashboard/lights/brightness")
    @ResponseBody
    public ResponseEntity<?> setLightBrightness(@RequestBody Map<String, Object> request) {
        Map<String, Object> response = new HashMap<>();

        try {
            int brightness = ((Number) request.get("brightness")).intValue();
            // Convert percentage (0-100) to Hue brightness (0-254)
            int hueBrightness = (brightness * 254) / 100;
            lightService.setBrightness(hueBrightness);

            // Update interpreter state to reflect the new brightness
            hueScriptInterpreter.updateLastKnownBrightness(brightness);

            response.put("success", true);
            response.put("message", "Brightness set to " + brightness + "%");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.ok(response);
        }
    }

    @GetMapping("/api/dashboard/status")
    @ResponseBody
    public ResponseEntity<?> getStatus() {
        Map<String, Object> status = new HashMap<>();
        boolean connected = hueBridgeService.testConnection();

        status.put("connected", connected);
        status.put("bridgeIp", hueBridgeService.getBridgeIp());
        status.put("apiKey", hueBridgeService.getApiKey());

        if (connected) {
            status.put("color", hueScriptInterpreter.getLastKnownColor());
            status.put("brightness", hueScriptInterpreter.getLastKnownBrightness());
            status.put("lightsOn", hueScriptInterpreter.getLastKnownLightState());
        }

        return ResponseEntity.ok(status);
    }
}
