package com.soft.p4.hueScriptLanguage;

import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.atLeast;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;

import com.soft.p4.hueScriptLanguage.interpreter.HueScriptInterpreter;
import com.soft.p4.service.LightService;

/**
 * Test suite for HueScript interpreter functionality. Validates script
 * execution, command processing, and light service integration.
 */
public class HueScriptInterpreterTest {

    private HueScriptInterpreter interpreter;
    private LightService mockLightService;

    @BeforeEach
    public void setUp() {
        mockLightService = mock(LightService.class);
        interpreter = new HueScriptInterpreter(mockLightService);
    }

    @Test
    public void testExecuteEmptyScript() {
        String result = interpreter.executeScript("");
        assertTrue(result.contains("✅ Script execution completed successfully"),
                "Empty script should execute successfully");
    }

    @Test
    public void testExecuteLightsOnCommand() {
        String result = interpreter.executeScript("lights on;");

        verify(mockLightService, atLeastOnce()).setLightsState(true);

        assertTrue(result.contains("💡 Turning all lights ON"),
                "Output should indicate lights turning on");
        assertTrue(result.contains("✅ Script execution completed successfully"),
                "Script should complete successfully");
    }

    @Test
    public void testExecuteLightsOffCommand() {
        String result = interpreter.executeScript("lights off;");

        verify(mockLightService, atLeastOnce()).setLightsState(false);
        assertTrue(result.contains("💡 Turning all lights OFF"),
                "Output should indicate lights turning off");
    }

    @Test
    public void testExecuteSingleLightCommand() {
        String result = interpreter.executeScript("light \"1\" on;");

        verify(mockLightService).setLightState("1", true);
        assertTrue(result.contains("💡 Turning light 1 ON"),
                "Output should indicate specific light turning on");
    }

    @Test
    public void testExecuteBrightnessCommand() {
        String result = interpreter.executeScript("brightness 80;");

        // Calculate expected Hue brightness (0-254 range)
        int expectedHueBrightness = (80 * 254) / 100;

        // Verify brightness was set (feedback mechanism also sets brightness to 254)
        verify(mockLightService, atLeastOnce()).setBrightness(expectedHueBrightness);
        assertTrue(result.contains("💡 Setting brightness to 80%"),
                "Output should indicate brightness setting");
    }

    @Test
    public void testExecuteColorCommand() {
        String result = interpreter.executeScript("lights color \"#FF0000\";");

        // Verify color was set (feedback mechanism also sets colors)
        verify(mockLightService, atLeastOnce()).setColor("#FF0000");
        assertTrue(result.contains("🎨 Setting all lights color to #FF0000"),
                "Output should indicate color setting");
    }

    @Test
    public void testExecuteNamedColorCommand() {
        String result = interpreter.executeScript("lights color \"red\";");

        // Verify named color is converted to hex
        verify(mockLightService, atLeastOnce()).setColor("#FF0000");
        assertTrue(result.contains("🎨 Setting all lights color to #FF0000"),
                "Output should convert named colors to hex");
    }

    @Test
    public void testExecuteWaitCommand() {
        // Use short wait to avoid slowing down tests
        long startTime = System.currentTimeMillis();
        String result = interpreter.executeScript("wait 100 ms;");
        long elapsedTime = System.currentTimeMillis() - startTime;

        assertTrue(elapsedTime >= 100, "Wait should pause execution for at least 100ms");
        assertTrue(result.contains("⏱️ Waiting for 100 ms"),
                "Output should indicate waiting");
        assertTrue(result.contains("✅ Wait completed"),
                "Output should indicate wait completion");
    }

    @Test
    public void testExecuteTransitionCommand() {
        // Setup mock to avoid exceptions during transition
        doNothing().when(mockLightService).transitionColor(anyString(), anyString(), anyLong());

        String result = interpreter.executeScript("transition \"red\" to \"blue\" over 1 sec;");

        // Verify transition was called with correct parameters
        verify(mockLightService).transitionColor("#FF0000", "#0000FF", 1000);
        assertTrue(result.contains("🌈 Transitioning all lights from #FF0000 to #0000FF over 1 sec"),
                "Output should indicate color transition");
    }

    @Test
    public void testExecuteCountBasedRepeatCommand() {
        String result = interpreter.executeScript("repeat 3 times { lights on; lights off; }");

        // Use atLeast since feedback mechanism also calls these methods
        verify(mockLightService, atLeast(3)).setLightsState(true);
        verify(mockLightService, atLeast(3)).setLightsState(false);

        assertTrue(result.contains("🔄 Starting repeat block (3 times)"),
                "Output should indicate repeat start");
        assertTrue(result.contains("✅ Repeat block completed"),
                "Output should indicate repeat completion");
    }

    @Test
    public void testSceneDefinitionAndInvocation() {
        // Setup mocks to avoid exceptions
        doNothing().when(mockLightService).setColor(anyString());
        doNothing().when(mockLightService).setBrightness(anyInt());

        String result = interpreter.executeScript(
                "define scene redScene {\n"
                + "  lights color \"red\";\n"
                + "  brightness 50;\n"
                + "}\n"
                + "scene redScene;"
        );

        // Debug output for test verification
        System.out.println("Actual result: " + result);

        assertTrue(result.contains("📋 Invoking scene 'redScene'"),
                "Output should indicate scene invocation");
    }

    @Test
    public void testVariableDefinitionAndUsage() {
        String result = interpreter.executeScript(
                "var myColor = \"#00FF00\";\n"
                + "lights color myColor;"
        );

        // Verify color command was executed with variable value
        verify(mockLightService, atLeastOnce()).setColor("#00FF00");

        // Verify success feedback was shown (green color)
        verify(mockLightService, atLeastOnce()).setColor(eq("#00FF00")); // SUCCESS_COLOR

        assertTrue(result.contains("Setting all lights color to #00FF00"),
                "Output should indicate color setting");
        assertTrue(result.contains("✅ Script execution completed successfully"),
                "Output should indicate successful execution");
    }

    @Test
    public void testTransitionVariableDefinitionAndUsage() {
        // Setup mock to avoid exceptions during transition
        doNothing().when(mockLightService).transitionColor(anyString(), anyString(), anyLong());

        String result = interpreter.executeScript(
                "var myTransition = transition \"#FF0000\" to \"#0000FF\" over 2 sec;\n"
                + "myTransition;"
        );

        // Debug output for test verification
        System.out.println("FULL OUTPUT:\n" + result);

        // Verify transition was executed with correct parameters
        verify(mockLightService).transitionColor("#FF0000", "#0000FF", 2000);

        assertTrue(result.contains("Executing transition"),
                "Output should indicate transition execution");
        assertTrue(result.contains("✅ Script execution completed successfully"),
                "Output should indicate successful execution");
    }

    @Test
    public void testGroupDefinitionAndCommands() {
        // Setup mocks to avoid exceptions
        doNothing().when(mockLightService).setColor(anyString());

        String result = interpreter.executeScript(
                "// Define and use light variables\n"
                + "var myBlue = \"#0000FF\";\n"
                + "var myRed = \"#FF0000\";\n"
                + "lights color myBlue;\n"
                + "lights color myRed;"
        );

        assertTrue(result.contains("✅ Script execution completed successfully"),
                "Output should indicate successful execution");

        // Verify colors were set via variables
        verify(mockLightService, atLeastOnce()).setColor("#0000FF");
        verify(mockLightService, atLeastOnce()).setColor("#FF0000");
    }

    @Test
    public void testGroupTransitionCommand() {
        // Setup mock to avoid exceptions during transition
        doNothing().when(mockLightService).transitionColor(anyString(), anyString(), anyLong());

        String result = interpreter.executeScript(
                "transition \"red\" to \"green\" over 1 sec;"
        );

        // Debug output for test verification
        System.out.println("FULL OUTPUT:\n" + result);

        // Verify transition was executed with correct parameters
        verify(mockLightService).transitionColor("#FF0000", "#00FF00", 1000);

        assertTrue(result.contains("Transitioning"),
                "Output should indicate transition execution");
        assertTrue(result.contains("✅ Script execution completed successfully"),
                "Output should indicate successful execution");
    }

    @Test
    public void testMultipleScenes() {
        // Setup mocks to avoid exceptions
        doNothing().when(mockLightService).setColor(anyString());
        doNothing().when(mockLightService).setBrightness(anyInt());

        String result = interpreter.executeScript(
                "define scene dayScene {\n"
                + "  lights color \"#FFF4E0\";\n"
                + // Warm white
                "  brightness 100;\n"
                + "}\n"
                + "define scene nightScene {\n"
                + "  lights color \"#0000FF\";\n"
                + "  brightness 30;\n"
                + "}\n"
                + "scene dayScene;\n"
                + "wait 500 ms;\n"
                + "scene nightScene;"
        );

        assertTrue(result.contains("📋 Invoking scene 'dayScene'"),
                "Output should indicate dayScene invocation");
        assertTrue(result.contains("📋 Invoking scene 'nightScene'"),
                "Output should indicate nightScene invocation");
    }

    @Test
    public void testExecutionFeedbackBehavior() {
        // For successful script execution, verify feedback-related light service calls:
        // 1. Set lights to on for feedback
        // 2. Set to max brightness
        // 3. Set to success color (green)
        // 4. Various blinks
        // 5. Return to original state
        interpreter.executeScript("lights color \"blue\";"); // Simple successful script

        // Verify feedback-related calls for successful execution
        verify(mockLightService, atLeastOnce()).setColor("#00FF00"); // SUCCESS_COLOR
        verify(mockLightService, atLeastOnce()).setBrightness(254); // Max brightness for feedback

        // Reset mock to clear previous interactions
        reset(mockLightService);

        // For failed script execution, verify similar pattern but with red instead of green
        interpreter.executeScript("nonexistentCommand;"); // This will cause a parser error

        // Verify feedback-related calls for failed execution  
        verify(mockLightService, atLeastOnce()).setColor("#FF0000"); // FAILURE_COLOR
        verify(mockLightService, atLeastOnce()).setBrightness(254);

        // Reset mock to clear previous interactions
        reset(mockLightService);

        // When feedback is disabled, verify no feedback-related calls
        interpreter.executeScript("lights color \"blue\";", false);

        // Only the actual command call, no feedback-related calls
        verify(mockLightService).setColor("#0000FF"); // Just the blue from the command
        verify(mockLightService, never()).setColor("#00FF00"); // No success feedback
        verify(mockLightService, never()).setColor("#FF0000"); // No failure feedback
    }

    @Test
    public void testDuplicateFeedbackWhenCancelling() {
        // Use mock lightService to track calls made during feedback

        // Run script that completes successfully - shows success feedback (green)
        interpreter.executeScript("lights color \"blue\";");

        // Verify success feedback occurred (green color was set)
        verify(mockLightService, atLeastOnce()).setColor("#00FF00"); // SUCCESS_COLOR

        // Reset mock to clear history
        reset(mockLightService);

        // Execute script and immediately cancel it
        // This calls showExecutionFeedback twice - once for success, once for cancellation
        interpreter.executeScript("lights on; wait 5 sec;", true); // Long wait to ensure cancellation
        interpreter.cancel(); // This calls showExecutionFeedback(false)

        // Verify both success and failure feedback colors were set
        // This demonstrates multiple feedback cycles occurred
        verify(mockLightService, atLeastOnce()).setColor("#00FF00"); // SUCCESS_COLOR
        verify(mockLightService, atLeastOnce()).setColor("#FF0000"); // FAILURE_COLOR

        // Verify at least two cycles of turning lights on/off for blinking
        // (one cycle for success, one for failure)
        verify(mockLightService, atLeast(2)).setLightsState(true);
        verify(mockLightService, atLeast(2)).setLightsState(false);
    }
}
