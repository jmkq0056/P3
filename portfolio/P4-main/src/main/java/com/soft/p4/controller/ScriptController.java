package com.soft.p4.controller;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.interpreter.HueScriptInterpreter;
import com.soft.p4.service.HueBridgeService;
import com.soft.p4.service.LightService;

@RestController
@RequestMapping("/api/scripts")
public class ScriptController {

    private HueScriptInterpreter interpreter;
    private final HueBridgeService hueBridgeService;
    private final WebApplicationContext applicationContext;

    // Track active SSE connections for real-time logging
    private final Map<String, SseEmitter> activeConnections = new ConcurrentHashMap<>();
    private final AtomicLong connectionIdCounter = new AtomicLong(0);

    @Autowired
    public ScriptController(HueScriptInterpreter interpreter, HueBridgeService hueBridgeService, WebApplicationContext applicationContext) {
        this.interpreter = interpreter;
        this.hueBridgeService = hueBridgeService;
        this.applicationContext = applicationContext;
    }

    // Synchronous execution endpoint for backward compatibility
    @PostMapping("/execute")
    public ResponseEntity<?> executeScript(@RequestBody Map<String, String> request) {
        try {
            // Validate bridge connectivity
            if (!hueBridgeService.testConnection()) {
                Map<String, Object> response = new HashMap<>();
                response.put("log", "❌ Hue Bridge connection failed. Check network and bridge status.");
                response.put("success", false);
                return ResponseEntity.ok(response);
            }

            String scriptContent = request.get("scriptContent");
            if (scriptContent == null || scriptContent.trim().isEmpty()) {
                return ResponseEntity.badRequest().body("Script content cannot be empty");
            }

            // Execute with visual feedback enabled
            String executionLog = interpreter.executeScript(scriptContent, true);

            if (executionLog == null) {
                executionLog = "";
            }
            Map<String, Object> response = new HashMap<>();
            response.put("log", executionLog);
            response.put("success", !executionLog.contains("❌"));

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error executing script: " + e.getMessage());
        }
    }

    @PostMapping("/execute-stream")
    public ResponseEntity<?> executeScriptStream(@RequestBody Map<String, String> request) {
        try {
            // Validate bridge connectivity
            if (!hueBridgeService.testConnection()) {
                Map<String, Object> response = new HashMap<>();
                response.put("connectionId", null);
                response.put("error", "❌ Hue Bridge connection failed. Check network and bridge status.");
                response.put("success", false);
                return ResponseEntity.ok(response);
            }

            String scriptContent = request.get("scriptContent");
            if (scriptContent == null || scriptContent.trim().isEmpty()) {
                return ResponseEntity.badRequest().body("Script content cannot be empty");
            }

            // Generate unique session ID for this execution
            String connectionId = "script_" + connectionIdCounter.incrementAndGet();

            // Execute asynchronously with real-time logging
            CompletableFuture.runAsync(() -> {
                try {
                    interpreter.executeScriptWithCallback(scriptContent, true, (logMessage) -> {
                        sendLogToClient(connectionId, logMessage, false);
                    });
                    // Signal successful completion
                    sendLogToClient(connectionId, "✅ Script execution completed successfully", true);
                } catch (Exception e) {
                    // Preserve detailed error information, especially from ParserException
                    String detailedErrorMessage;
                    if (e instanceof ParserException) {
                        // ParserException contains formatted line/position info
                        detailedErrorMessage = "❌ " + e.getMessage();
                    } else {
                        // Include full error details for other exceptions
                        detailedErrorMessage = "❌ Execution error: " + e.getMessage();

                        // Include cause if available
                        if (e.getCause() != null && e.getCause().getMessage() != null) {
                            detailedErrorMessage += "\nCause: " + e.getCause().getMessage();
                        }
                    }
                    sendLogToClient(connectionId, detailedErrorMessage, true);
                }
            });

            Map<String, Object> response = new HashMap<>();
            response.put("connectionId", connectionId);
            response.put("success", true);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error starting script execution: " + e.getMessage());
        }
    }

    @GetMapping(value = "/logs", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamLogs(@RequestParam String connectionId) {
        SseEmitter emitter = new SseEmitter(300000L); // 5-minute timeout

        // Register connection for log streaming
        activeConnections.put(connectionId, emitter);

        // Clean up on completion, timeout, or error
        emitter.onCompletion(() -> activeConnections.remove(connectionId));
        emitter.onTimeout(() -> activeConnections.remove(connectionId));
        emitter.onError((ex) -> activeConnections.remove(connectionId));

        // Send initial connection confirmation
        try {
            emitter.send(SseEmitter.event()
                    .name("connected")
                    .data("// Connected to real-time log stream..."));
        } catch (Exception e) {
            activeConnections.remove(connectionId);
        }

        return emitter;
    }

    private void sendLogToClient(String connectionId, String logMessage, boolean isComplete) {
        SseEmitter emitter = activeConnections.get(connectionId);
        if (emitter != null) {
            try {
                Map<String, Object> data = new HashMap<>();
                data.put("message", logMessage);
                data.put("complete", isComplete);
                data.put("timestamp", System.currentTimeMillis());

                emitter.send(SseEmitter.event()
                        .name(isComplete ? "complete" : "log")
                        .data(data));

                if (isComplete) {
                    emitter.complete();
                    activeConnections.remove(connectionId);
                }
            } catch (Exception e) {
                activeConnections.remove(connectionId);
            }
        }
    }

    // Reset interpreter state for debugging purposes
    @PostMapping("/reset-state")
    public ResponseEntity<?> resetInterpreterState() {
        try {
            // Create fresh interpreter instance
            interpreter = new HueScriptInterpreter(
                    applicationContext.getBean(LightService.class)
            );

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Interpreter state reset successfully");
            response.put("success", true);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error resetting interpreter state: " + e.getMessage());
        }
    }

    @GetMapping("/test-connection")
    public ResponseEntity<?> testConnection() {
        try {
            boolean connected = hueBridgeService.testConnection();

            Map<String, Object> response = new HashMap<>();
            response.put("connected", connected);
            response.put("bridgeIp", "REMOVED_FOR_SECURITY");

            if (connected) {
                response.put("message", "Successfully connected to Hue Bridge");
            } else {
                response.put("message", "Failed to connect to Hue Bridge. Check network and bridge status.");
            }

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error testing connection: " + e.getMessage());
        }
    }
}
