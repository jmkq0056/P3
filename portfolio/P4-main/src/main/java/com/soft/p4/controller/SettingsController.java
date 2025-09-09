package com.soft.p4.controller;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.request.async.DeferredResult;

import com.soft.p4.service.HueBridgeService;

@RestController
@RequestMapping("/api/settings")
public class SettingsController {

    private final HueBridgeService hueBridgeService;

    @Autowired
    public SettingsController(HueBridgeService hueBridgeService) {
        this.hueBridgeService = hueBridgeService;
        System.out.println("SettingsController initialized with HueBridgeService");
    }

    @GetMapping("/bridge")
    public ResponseEntity<?> getBridgeSettings() {
        System.out.println("GET /api/settings/bridge called");
        try {
            Map<String, Object> settings = new HashMap<>();
            settings.put("bridgeIp", hueBridgeService.getBridgeIp());
            settings.put("apiKey", hueBridgeService.getApiKey());
            System.out.println("Returning bridge settings: IP=" + hueBridgeService.getBridgeIp() + ", API Key=" + hueBridgeService.getApiKey());
            return ResponseEntity.ok(settings);
        } catch (Exception e) {
            System.err.println("Error in getBridgeSettings: " + e.getMessage());
            e.printStackTrace();

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to retrieve bridge settings: " + e.getMessage());
            return ResponseEntity.ok(errorResponse);
        }
    }

    @PostMapping("/bridge")
    public DeferredResult<ResponseEntity<?>> updateBridgeSettings(@RequestBody Map<String, String> request) {
        System.out.println("POST /api/settings/bridge called with data: " + request);

        // Configure response timeout
        DeferredResult<ResponseEntity<?>> deferredResult = new DeferredResult<>(15000L);

        // Handle timeout scenario
        deferredResult.onTimeout(() -> {
            Map<String, Object> timeoutResponse = new HashMap<>();
            timeoutResponse.put("success", false);
            timeoutResponse.put("error", "Request timed out. The server is taking too long to process your request.");
            deferredResult.setResult(ResponseEntity.ok(timeoutResponse));
            System.err.println("Request timed out for bridge settings update");
        });

        // Process request asynchronously
        CompletableFuture.runAsync(() -> {
            Map<String, Object> response = new HashMap<>();

            try {
                String bridgeIp = request.get("bridgeIp");
                String apiKey = request.get("apiKey");

                System.out.println("Received settings - Bridge IP: " + bridgeIp + ", API Key: " + apiKey);

                // Validate bridge IP
                if (bridgeIp == null || bridgeIp.trim().isEmpty()) {
                    System.out.println("Bridge IP validation failed - empty value");
                    response.put("success", false);
                    response.put("error", "Bridge IP cannot be empty");
                    deferredResult.setResult(ResponseEntity.ok(response));
                    return;
                }

                // Validate API key
                if (apiKey == null || apiKey.trim().isEmpty()) {
                    System.out.println("API Key validation failed - empty value");
                    response.put("success", false);
                    response.put("error", "API Key cannot be empty");
                    deferredResult.setResult(ResponseEntity.ok(response));
                    return;
                }

                // Update bridge configuration
                System.out.println("Updating bridge settings in service");
                hueBridgeService.updateBridgeSettings(bridgeIp, apiKey);

                // Verify connectivity
                System.out.println("Testing connection with new settings");
                boolean connected = hueBridgeService.testConnection();
                System.out.println("Connection test result: " + (connected ? "Connected" : "Not Connected"));

                response.put("success", true);
                response.put("connected", connected);
                response.put("message", "Bridge settings updated successfully");

                deferredResult.setResult(ResponseEntity.ok(response));
            } catch (Exception e) {
                System.err.println("Error in updateBridgeSettings: " + e.getMessage());
                e.printStackTrace();

                response.put("success", false);
                response.put("error", "Error updating bridge settings: " + e.getMessage());
                deferredResult.setResult(ResponseEntity.ok(response));
            }
        });

        return deferredResult;
    }
}
