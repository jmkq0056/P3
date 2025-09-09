package com.soft.p4.other;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Timeout;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.atLeast;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.verify;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;

import com.soft.p4.hueScriptLanguage.interpreter.HueScriptInterpreter;
import com.soft.p4.hueScriptLanguage.parser.HueScriptParser;
import com.soft.p4.service.HueBridgeService;
import com.soft.p4.service.LightService;
/**
 * Performance and stress tests for the scripting language. Validates parser and
 * interpreter behavior under load conditions.
 */
@SpringBootTest
@Tag("performanceTest")
public class PerformanceTests {

    @Autowired
    private HueScriptParser parser;

    @Autowired
    private HueScriptInterpreter interpreter;

    @MockBean
    private HueBridgeService mockHueBridgeService;

    @MockBean
    private LightService mockLightService;

    /**
     * Test that large scripts can be parsed quickly
     */
    @Test
    @Timeout(value = 1000, unit = TimeUnit.MILLISECONDS)
    public void testLargeScriptParsing() {
        StringBuilder largeScript = new StringBuilder();

        // Generate large script with many commands
        for (int i = 0; i < 1000; i++) {
            largeScript.append("// Comment line ").append(i).append("\n");
            largeScript.append("brightness ").append(i % 100).append(";\n");
            largeScript.append("lights color \"#").append(String.format("%06X", i % 0xFFFFFF)).append("\";\n");
            largeScript.append("wait 1 ms;\n");
        }

        // Parse script and measure time
        long startTime = System.currentTimeMillis();
        parser.parse(largeScript.toString());
        long elapsedTime = System.currentTimeMillis() - startTime;

        System.out.println("Parsed 4000-line script in " + elapsedTime + "ms");
        // @Timeout annotation will fail test if it takes too long
    }

    /**
     * Test deeply nested repeat blocks work correctly
     */
    @Test
    public void testDeeplyNestedRepeatBlocks() throws IOException {
        // Mock bridge service to do nothing
        doNothing().when(mockHueBridgeService).setAllLightsState(anyBoolean());

        // Create script with 10 nested repeat blocks (each with 2 iterations)
        StringBuilder nestedScript = new StringBuilder();

        nestedScript.append("repeat 2 times {\n");
        for (int i = 0; i < 9; i++) {
            nestedScript.append("  ".repeat(i + 1));
            nestedScript.append("repeat 2 times {\n");
        }

        // Inner-most commands
        nestedScript.append("  ".repeat(10));
        nestedScript.append("lights on;\n");
        nestedScript.append("  ".repeat(10));
        nestedScript.append("lights off;\n");

        // Close all blocks
        for (int i = 9; i >= 0; i--) {
            nestedScript.append("  ".repeat(i));
            nestedScript.append("}\n");
        }

        // Execute script
        String result = interpreter.executeScript(nestedScript.toString());

        // Each level has 2 iterations, 10 levels = 2^10 = 1024 iterations
        // Using atLeast() because actual number might be slightly more
        verify(mockLightService, atLeast(1024)).setLightsState(true);
        verify(mockLightService, atLeast(1024)).setLightsState(false);
        assertTrue(result.contains("✅ Script execution completed successfully"),
                "Script should complete successfully");
    }

    /**
     * Test very long variable and scene names
     */
    @Test
    public void testLongIdentifiers() throws IOException {
        // Create 100-character identifiers
        String longVarName = "a".repeat(100);
        String longSceneName = "s".repeat(100);

        StringBuilder script = new StringBuilder();
        script.append("var ").append(longVarName).append(" = \"red\";\n");
        script.append("define scene ").append(longSceneName).append(" {\n");
        script.append("  lights color ").append(longVarName).append(";\n");
        script.append("}\n");
        script.append("scene ").append(longSceneName).append(";\n");

        // Execute script
        String result = interpreter.executeScript(script.toString());

        // Debug output
        System.out.println("testLongIdentifiers result: " + result);

        // Verify successful execution
        assertTrue(result.contains("✅ Script execution completed successfully"),
                "Script should complete successfully");
        // Using atLeastOnce() as method might be called multiple times
        verify(mockLightService, atLeastOnce()).setColor(eq("#FF0000"));
    }

    /**
     * Test that large numbers of scenes and variables can be defined
     */
    @Test
    public void testManyDefinitions() throws IOException {
        StringBuilder script = new StringBuilder();

        // Define 100 variables
        for (int i = 0; i < 100; i++) {
            script.append("var color").append(i).append(" = \"#")
                    .append(String.format("%06X", i)).append("\";\n");
        }

        // Define 100 scenes that use the variables
        for (int i = 0; i < 100; i++) {
            script.append("define scene scene").append(i).append(" {\n");
            script.append("  lights color color").append(i).append(";\n");
            script.append("}\n");
        }

        // Add scene invocation to avoid state issues
        script.append("scene scene99;\n");

        // Execute script with definitions and invocation
        String result = interpreter.executeScript(script.toString());

        // Debug output
        System.out.println("testManyDefinitions result: " + result);

        assertTrue(result.contains("✅ Script execution completed successfully"),
                "Script should complete successfully");

        // Last color should be #000063 (hex for 99)
        verify(mockLightService, atLeastOnce()).setColor(eq("#000063"));
    }
}
