package com.soft.p4.hueScriptLanguage.interpreter;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Consumer;

import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.Command;
import com.soft.p4.hueScriptLanguage.ast.command.all.BrightnessCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.ColorCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.LightCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.RepeatCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.SceneCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.SceneInvocationCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.TransitionCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.VariableInvocationCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.WaitCommand;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupBrightnessCommand;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupColorCommand;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupDefineCommand;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupLightCommand;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupTransitionCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.parser.HueScriptParser;
import com.soft.p4.service.LightService;

/**
 * Executes Hue script AST by visiting nodes and translating commands to Hue
 * Bridge API calls. Maintains execution state and handles variables, scenes,
 * groups with optional visual feedback.
 */
@Component
public class HueScriptInterpreter implements NodeVisitor {

    private final StringBuilder log = new StringBuilder();
    private final AtomicBoolean isCancelled = new AtomicBoolean(false);
    private final AtomicBoolean feedbackShown = new AtomicBoolean(false);
    private Map<String, String> variables = new HashMap<>();
    private Map<String, SceneCommand> scenes = new HashMap<>();
    private Map<String, List<String>> groups = new HashMap<>();

    private Consumer<String> logCallback = null;

    // Track current light state for feedback restoration
    private String lastKnownColor = "#BB60D5";
    private int lastKnownBrightness = 100;
    private boolean lastKnownLightState = true;

    // Visual feedback configuration
    private static final String SUCCESS_COLOR = "#00FF00";
    private static final String FAILURE_COLOR = "#FF0000";
    private static final int BLINK_COUNT = 3;
    private static final int BLINK_DURATION_MS = 500;

    private final LightService lightService;

    public HueScriptInterpreter(LightService lightService) {
        this.lightService = lightService;
    }

    /**
     * Registers a variable for script use. Variables store colors, brightness,
     * or transitions.
     */
    public void registerVariable(String name, String value) {
        variables.put(name, value);
    }

    /**
     * Registers a reusable scene containing a sequence of commands.
     */
    public void registerScene(String name, SceneCommand scene) {
        scenes.put(name, scene);
    }

    /**
     * Registers a light group for collective control operations.
     */
    public void registerGroup(String name, List<String> lightIds) {
        groups.put(name, lightIds);
    }

    public String executeScript(String scriptContent) {
        return executeScript(scriptContent, true);
    }

    public String executeScript(String scriptContent, boolean showFeedback) {
        return executeScriptWithCallback(scriptContent, showFeedback, null);
    }

    /**
     * Executes script with optional visual feedback and real-time logging
     * callback. Preserves variable/scene/group definitions between executions.
     *
     * @param scriptContent Script source code
     * @param showFeedback Whether to blink lights on completion
     * @param callback Optional real-time log callback
     * @return Complete execution log
     */
    public String executeScriptWithCallback(String scriptContent, boolean showFeedback, Consumer<String> callback) {
        try {
            log.setLength(0);
            isCancelled.set(false);
            feedbackShown.set(false);
            this.logCallback = callback;

            HueScriptParser parser = new HueScriptParser();
            parser.setExistingVariables(variables);
            parser.setExistingScenes(scenes);
            parser.setExistingGroups(groups);

            ScriptNode scriptNode = parser.parse(scriptContent);

            this.variables.putAll(parser.getVariables());
            this.scenes.putAll(parser.getScenes());
            this.groups.putAll(parser.getGroups());

            for (SceneCommand scene : parser.getScenes().values()) {
                scene.accept(this);
            }

            scriptNode.accept(this);

            if (!isCancelled.get() && showFeedback && !feedbackShown.get()) {
                showExecutionFeedback(true);
            }

            String completionMessage = "✅ Script execution completed successfully\n";
            appendLog(completionMessage);
            return log.toString();
        } catch (Exception e) {
            String errorMessage;
            if (e instanceof ParserException) {
                // Log error but re-throw to preserve detailed error info in controller
                errorMessage = "❌ " + e.getMessage() + "\n";
                appendLog(errorMessage);

                if (showFeedback && !feedbackShown.get()) {
                    showExecutionFeedback(false);
                }

                // Re-throw to maintain detailed error reporting
                throw e;
            } else {
                // Handle runtime errors normally
                errorMessage = "❌ Execution error: " + e.getMessage() + "\n";

                // Include cause details if available
                if (e.getCause() != null && e.getCause().getMessage() != null) {
                    errorMessage += "Cause: " + e.getCause().getMessage() + "\n";
                }

                appendLog(errorMessage);

                if (showFeedback && !feedbackShown.get()) {
                    showExecutionFeedback(false);
                }

                return log.toString();
            }
        } finally {
            this.logCallback = null;
        }
    }

    /**
     * Appends message to log and notifies real-time callback if registered.
     */
    private void appendLog(String message) {
        log.append(message);
        if (logCallback != null) {
            logCallback.accept(message.trim());
        }
    }

    /**
     * Provides visual execution feedback by blinking lights. Saves and restores
     * previous light state.
     */
    private void showExecutionFeedback(boolean success) {
        try {
            boolean originalLightState = lastKnownLightState;
            String originalColor = lastKnownColor;
            int originalBrightness = lastKnownBrightness;

            if (!lastKnownLightState) {
                lightService.setLightsState(true);
            }

            lightService.setBrightness(254);
            String feedbackColor = success ? SUCCESS_COLOR : FAILURE_COLOR;

            for (int i = 0; i < BLINK_COUNT; i++) {
                lightService.setColor(feedbackColor);
                Thread.sleep(BLINK_DURATION_MS);

                lightService.setLightsState(false);
                Thread.sleep(BLINK_DURATION_MS / 2);

                lightService.setLightsState(true);
            }

            if (originalLightState) {
                lightService.setColor(originalColor);
                int hueBrightness = (originalBrightness * 254) / 100;
                lightService.setBrightness(hueBrightness);
            } else {
                lightService.setLightsState(false);
            }

            appendLog("🔔 Visual feedback: " + (success ? "success" : "failure") + " indication shown\n");
            feedbackShown.set(true);

        } catch (Exception e) {
            appendLog("⚠️ Unable to show visual feedback: " + e.getMessage() + "\n");
            try {
                if (lastKnownLightState) {
                    lightService.setLightsState(true);
                    lightService.setColor(lastKnownColor);
                    int hueBrightness = (lastKnownBrightness * 254) / 100;
                    lightService.setBrightness(hueBrightness);
                } else {
                    lightService.setLightsState(false);
                }
            } catch (Exception restoreException) {
                appendLog("⚠️ Failed to restore lights: " + restoreException.getMessage() + "\n");
            }
        }
    }

    @Override
    public void visit(ScriptNode node) {
        for (var command : node.getCommands()) {
            if (isCancelled.get()) {
                appendLog("⛔ Execution cancelled\n");
                break;
            }
            command.accept(this);
        }
    }

    @Override
    public void visit(LightCommand node) {
        try {
            if (node.isGlobal()) {
                if (node.getAction() == LightCommand.Action.ON) {
                    appendLog("💡 Turning all lights ON...\n");
                    lightService.setLightsState(true);
                    lastKnownLightState = true;
                } else if (node.getAction() == LightCommand.Action.OFF) {
                    appendLog("💡 Turning all lights OFF...\n");
                    lightService.setLightsState(false);
                    lastKnownLightState = false;
                }
            } else {
                String lightId = node.getLightId();
                if (node.getAction() == LightCommand.Action.ON) {
                    appendLog("💡 Turning light " + lightId + " ON...\n");
                    lightService.setLightState(lightId, true);
                } else if (node.getAction() == LightCommand.Action.OFF) {
                    appendLog("💡 Turning light " + lightId + " OFF...\n");
                    lightService.setLightState(lightId, false);
                }
            }
        } catch (Exception e) {
            throw new RuntimeException("Error executing light command at line "
                    + node.getLineNumber() + ": " + e.getMessage(), e);
        }
    }

    @Override
    public void visit(BrightnessCommand node) {
        try {
            int level = node.getLevel();

            if (node.isGlobal()) {
                appendLog("💡 Setting brightness to " + level + "%...\n");
                lastKnownBrightness = level;
                int hueBrightness = (level * 254) / 100;
                lightService.setBrightness(hueBrightness);
            } else {
                String lightId = node.getLightId();
                appendLog("💡 Setting light " + lightId + " brightness to " + level + "%...\n");
                int hueBrightness = (level * 254) / 100;
                lightService.setLightBrightness(lightId, hueBrightness);
            }
        } catch (Exception e) {
            throw new RuntimeException("Error executing brightness command at line "
                    + node.getLineNumber() + ": " + e.getMessage(), e);
        }
    }

    @Override
    public void visit(ColorCommand node) {
        try {
            String colorValue = node.getColorValue();

            if (node.isGlobal()) {
                appendLog("🎨 Setting all lights color to " + colorValue + "...\n");
                lastKnownColor = colorValue;
                lightService.setColor(colorValue);
            } else {
                String lightId = node.getLightId();
                appendLog("🎨 Setting light " + lightId + " color to " + colorValue + "...\n");
                lightService.setLightColor(lightId, colorValue);
            }
        } catch (Exception e) {
            throw new RuntimeException("Error executing color command at line "
                    + node.getLineNumber() + ": " + e.getMessage(), e);
        }
    }

    @Override
    public void visit(WaitCommand node) {
        try {
            long waitTime = node.getDurationInMillis();
            String timeUnitDisplay = node.getTimeUnit().isEmpty() ? "seconds" : node.getTimeUnit();

            appendLog("⏱️ Waiting for " + node.getDuration() + " " + timeUnitDisplay + "...\n");
            Thread.sleep(waitTime);
            appendLog("✅ Wait completed\n");
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Wait interrupted at line "
                    + node.getLineNumber() + ": " + e.getMessage(), e);
        } catch (Exception e) {
            throw new RuntimeException("Error executing wait command at line "
                    + node.getLineNumber() + ": " + e.getMessage(), e);
        }
    }

    @Override
    public void visit(RepeatCommand node) {
        try {
            List<Command> commands = node.getCommands();

            if (node.isTimeBased()) {
                long durationMs = node.getDuration();
                String timeUnitDisplay = node.getTimeUnit().isEmpty() ? "milliseconds" : node.getTimeUnit();

                appendLog("🔄 Starting repeat block for " + durationMs / 1000 + " " + timeUnitDisplay + "...\n");

                long startTime = System.currentTimeMillis();
                long endTime = startTime + durationMs;
                int iterationCount = 0;

                while (System.currentTimeMillis() < endTime && !isCancelled.get()) {
                    iterationCount++;
                    appendLog("🔄 Iteration " + iterationCount + " (Time remaining: "
                            + ((endTime - System.currentTimeMillis()) / 1000) + " seconds)\n");

                    for (Command command : commands) {
                        if (isCancelled.get() || System.currentTimeMillis() >= endTime) {
                            break;
                        }
                        command.accept(this);
                    }
                }

                appendLog("✅ Time-based repeat block completed after " + iterationCount + " iterations\n");
            } else {
                int repeatTimes = node.getTimes();
                appendLog("🔄 Starting repeat block (" + repeatTimes + " times)...\n");

                for (int i = 0; i < repeatTimes; i++) {
                    if (isCancelled.get()) {
                        appendLog("⛔ Execution cancelled\n");
                        break;
                    }

                    appendLog("🔄 Iteration " + (i + 1) + " of " + repeatTimes + "\n");

                    for (Command command : commands) {
                        if (isCancelled.get()) {
                            break;
                        }
                        command.accept(this);
                    }
                }

                appendLog("✅ Repeat block completed\n");
            }
        } catch (Exception e) {
            throw new RuntimeException("Error executing repeat command at line "
                    + node.getLineNumber() + ": " + e.getMessage(), e);
        }
    }

    @Override
    public void visit(TransitionCommand node) {
        try {
            String fromColorValue = node.getFromColorValue();
            String toColorValue = node.getToColorValue();
            long durationMs = node.getDurationInMillis();
            String timeUnitDisplay = node.getTimeUnit().isEmpty() ? "milliseconds" : node.getTimeUnit();

            if (node.isGlobal()) {
                appendLog("🌈 Transitioning all lights from " + fromColorValue + " to " + toColorValue
                        + " over " + node.getDuration() + " " + timeUnitDisplay + "...\n");
                lastKnownColor = toColorValue;
                lightService.transitionColor(fromColorValue, toColorValue, (int) durationMs);
            } else {
                String lightId = node.getLightId();
                appendLog("🌈 Transitioning light " + lightId + " from " + fromColorValue + " to " + toColorValue
                        + " over " + node.getDuration() + " " + timeUnitDisplay + "...\n");
                lightService.transitionLightColor(lightId, fromColorValue, toColorValue, (int) durationMs);
            }

            appendLog("✅ Color transition completed\n");
        } catch (Exception e) {
            throw new RuntimeException("Error executing transition command at line "
                    + node.getLineNumber() + ": " + e.getMessage(), e);
        }
    }

    @Override
    public void visit(SceneInvocationCommand node) {
        String sceneName = node.getSceneName();
        appendLog("🔍 Looking for scene '" + sceneName + "', available scenes: " + scenes.keySet() + "\n");

        SceneCommand scene = scenes.get(sceneName);
        if (scene == null) {
            throw new RuntimeException("Scene '" + sceneName + "' not found");
        }

        appendLog("📋 Invoking scene '" + sceneName + "'...\n");

        for (Command cmd : scene.getCommands()) {
            if (isCancelled.get()) {
                appendLog("⛔ Execution cancelled\n");
                break;
            }
            cmd.accept(this);
        }

        appendLog("✅ Scene '" + sceneName + "' execution completed\n");
    }

    @Override
    public void visit(SceneCommand node) {
        appendLog("📋 Scene '" + node.getName() + "' defined with "
                + node.getCommands().size() + " commands\n");
    }

    @Override
    public void visit(VariableInvocationCommand node) {
        try {
            String variableName = node.getVariableName();
            appendLog("🔍 Executing variable '" + variableName + "'...\n");
            executeVariable(variableName);
            appendLog("✅ Variable execution completed\n");
        } catch (Exception e) {
            throw new RuntimeException("Error executing variable at line "
                    + node.getLineNumber() + ": " + e.getMessage(), e);
        }
    }

    /**
     * Executes variable value as command. Handles colors, brightness, and
     * transitions.
     */
    private void executeVariable(String variableName) {
        String value = variables.get(variableName);
        if (value == null) {
            throw new RuntimeException("Variable '" + variableName + "' not found");
        }

        // Check for JSON transition format first
        try {
            ObjectMapper mapper = new ObjectMapper();
            JsonNode jsonNode = mapper.readTree(value);

            if (jsonNode.has("transition")) {
                executeTransitionVariable(value);
                return;
            }
        } catch (Exception e) {
            // Not JSON, continue with other formats
        }

        // Try parsing as brightness value
        try {
            int brightness = Integer.parseInt(value);
            if (brightness >= 0 && brightness <= 100) {
                BrightnessCommand brightnessCmd = new BrightnessCommand(brightness, -1);
                visit(brightnessCmd);
                return;
            }
        } catch (NumberFormatException e) {
            // Not a number, continue
        }

        // Default to color value
        ColorCommand colorCmd = new ColorCommand(value, -1);
        visit(colorCmd);
    }

    /**
     * Executes transition stored in variable. Format: {"transition": {"from":
     * "#color1", "to": "#color2", "duration": 1000}}
     */
    private void executeTransitionVariable(String transitionDefinition) {
        try {
            ObjectMapper mapper = new ObjectMapper();
            JsonNode jsonNode = mapper.readTree(transitionDefinition);

            JsonNode transitionNode = jsonNode.get("transition");
            if (transitionNode == null) {
                throw new RuntimeException("Invalid transition format: missing 'transition' object");
            }

            String fromColor = transitionNode.get("from").asText();
            String toColor = transitionNode.get("to").asText();
            int duration = transitionNode.get("duration").asInt();

            TransitionCommand transitionCmd = new TransitionCommand(fromColor, toColor, duration, "ms", -1);
            visit(transitionCmd);
        } catch (Exception e) {
            throw new RuntimeException("Error parsing transition definition: " + e.getMessage(), e);
        }
    }

    @Override
    public void visit(GroupDefineCommand node) {
        String groupName = node.getName();
        List<String> lightIds = node.getLightIds();
        groups.put(groupName, lightIds);
        appendLog("👥 Defined group '" + groupName + "' with " + lightIds.size() + " lights\n");
    }

    @Override
    public void visit(GroupLightCommand node) {
        try {
            String groupName = node.getGroupName();
            List<String> lightIds = groups.get(groupName);

            if (lightIds == null) {
                throw new RuntimeException("Group '" + groupName + "' not found");
            }

            appendLog("👥 Executing light command for group '" + groupName + "'...\n");

            for (String lightId : lightIds) {
                if (isCancelled.get()) {
                    break;
                }

                // Convert group action to individual light action
                LightCommand.Action action = node.getAction() == GroupLightCommand.Action.ON
                        ? LightCommand.Action.ON : LightCommand.Action.OFF;
                LightCommand lightCmd = new LightCommand(action, lightId, node.getLineNumber());
                visit(lightCmd);
            }
        } catch (Exception e) {
            throw new RuntimeException("Error executing group light command at line "
                    + node.getLineNumber() + ": " + e.getMessage(), e);
        }
    }

    @Override
    public void visit(GroupBrightnessCommand node) {
        try {
            String groupName = node.getGroupName();
            List<String> lightIds = groups.get(groupName);

            if (lightIds == null) {
                throw new RuntimeException("Group '" + groupName + "' not found");
            }

            appendLog("👥 Setting brightness for group '" + groupName + "'...\n");

            for (String lightId : lightIds) {
                if (isCancelled.get()) {
                    break;
                }

                BrightnessCommand brightnessCmd = new BrightnessCommand(node.getLevel(), lightId, node.getLineNumber());
                visit(brightnessCmd);
            }
        } catch (Exception e) {
            throw new RuntimeException("Error executing group brightness command at line "
                    + node.getLineNumber() + ": " + e.getMessage(), e);
        }
    }

    @Override
    public void visit(GroupColorCommand node) {
        try {
            String groupName = node.getGroupName();
            List<String> lightIds = groups.get(groupName);

            if (lightIds == null) {
                throw new RuntimeException("Group '" + groupName + "' not found");
            }

            appendLog("👥 Setting color for group '" + groupName + "'...\n");

            for (String lightId : lightIds) {
                if (isCancelled.get()) {
                    break;
                }

                ColorCommand colorCmd = new ColorCommand(node.getColorValue(), lightId, node.getLineNumber());
                visit(colorCmd);
            }
        } catch (Exception e) {
            throw new RuntimeException("Error executing group color command at line "
                    + node.getLineNumber() + ": " + e.getMessage(), e);
        }
    }

    @Override
    public void visit(GroupTransitionCommand node) {
        try {
            String groupName = node.getGroupName();
            List<String> lightIds = groups.get(groupName);

            if (lightIds == null) {
                throw new RuntimeException("Group '" + groupName + "' not found");
            }

            appendLog("👥 Executing color transition for group '" + groupName + "'...\n");

            for (String lightId : lightIds) {
                if (isCancelled.get()) {
                    break;
                }

                TransitionCommand transitionCmd = new TransitionCommand(
                        node.getFromColorValue(),
                        node.getToColorValue(),
                        node.getDuration(),
                        node.getTimeUnit(),
                        lightId,
                        node.getLineNumber()
                );
                visit(transitionCmd);
            }
        } catch (Exception e) {
            throw new RuntimeException("Error executing group transition command at line "
                    + node.getLineNumber() + ": " + e.getMessage(), e);
        }
    }

    /**
     * Cancels currently executing script. Thread-safe.
     */
    public void cancel() {
        isCancelled.set(true);
    }

    public String getLastKnownColor() {
        return lastKnownColor;
    }

    public int getLastKnownBrightness() {
        return lastKnownBrightness;
    }

    public boolean getLastKnownLightState() {
        return lastKnownLightState;
    }

    /**
     * Updates the last known color (for dashboard API consistency)
     */
    public void updateLastKnownColor(String color) {
        this.lastKnownColor = color;
    }

    /**
     * Updates the last known brightness (for dashboard API consistency)
     */
    public void updateLastKnownBrightness(int brightness) {
        this.lastKnownBrightness = brightness;
    }

    /**
     * Updates the last known light state (for dashboard API consistency)
     */
    public void updateLastKnownLightState(boolean state) {
        this.lastKnownLightState = state;
    }

    public Map<String, String> getVariables() {
        return new HashMap<>(variables);
    }

    public Map<String, SceneCommand> getScenes() {
        return new HashMap<>(scenes);
    }

    public Map<String, List<String>> getGroups() {
        return new HashMap<>(groups);
    }
}
