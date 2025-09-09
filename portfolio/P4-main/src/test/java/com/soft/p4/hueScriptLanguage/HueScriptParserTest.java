package com.soft.p4.hueScriptLanguage;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.all.BrightnessCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.ColorCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.LightCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.RepeatCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.SceneCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.TransitionCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.WaitCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.parser.HueScriptParser;

/**
 * Test suite for HueScript parser functionality. Validates command parsing, AST
 * generation, and error handling.
 */
public class HueScriptParserTest {

    private HueScriptParser parser;

    @BeforeEach
    public void setUp() {
        parser = new HueScriptParser();
    }

    @Test
    public void testParseEmptyScript() {
        ScriptNode result = parser.parse("");
        assertTrue(result.getCommands().isEmpty(), "Empty script should result in no commands");
    }

    @Test
    public void testParseLightsOnCommand() {
        ScriptNode result = parser.parse("lights on;");

        assertEquals(1, result.getCommands().size(), "Script should have 1 command");
        assertTrue(result.getCommands().get(0) instanceof LightCommand, "Command should be a LightCommand");
        LightCommand cmd = (LightCommand) result.getCommands().get(0);
        assertEquals(LightCommand.Action.ON, cmd.getAction(), "Action should be ON");
    }

    @Test
    public void testParseLightsOffCommand() {
        ScriptNode result = parser.parse("lights off;");

        assertEquals(1, result.getCommands().size(), "Script should have 1 command");
        assertTrue(result.getCommands().get(0) instanceof LightCommand, "Command should be a LightCommand");
        LightCommand cmd = (LightCommand) result.getCommands().get(0);
        assertEquals(LightCommand.Action.OFF, cmd.getAction(), "Action should be OFF");
    }

    @Test
    public void testParseBrightnessCommand() {
        ScriptNode result = parser.parse("brightness 75;");

        assertEquals(1, result.getCommands().size(), "Script should have 1 command");
        assertTrue(result.getCommands().get(0) instanceof BrightnessCommand, "Command should be a BrightnessCommand");
        BrightnessCommand cmd = (BrightnessCommand) result.getCommands().get(0);
        assertEquals(75, cmd.getLevel(), "Brightness level should be 75");
    }

    @Test
    public void testInvalidBrightnessValue() {
        assertThrows(ParserException.class, () -> parser.parse("brightness 101;"),
                "Brightness over 100 should throw exception");

        assertThrows(ParserException.class, () -> parser.parse("brightness -5;"),
                "Negative brightness should throw exception");
    }

    @Test
    public void testParseColorCommand() {
        ScriptNode result = parser.parse("lights color \"red\";");

        assertEquals(1, result.getCommands().size(), "Script should have 1 command");
        assertTrue(result.getCommands().get(0) instanceof ColorCommand, "Command should be a ColorCommand");
        ColorCommand cmd = (ColorCommand) result.getCommands().get(0);
        assertEquals("#FF0000", cmd.getColorValue(), "Color should be resolved to #FF0000 (red)");
    }

    @Test
    public void testParseWaitCommand() {
        ScriptNode result = parser.parse("wait 5 sec;");

        assertEquals(1, result.getCommands().size(), "Script should have 1 command");
        assertTrue(result.getCommands().get(0) instanceof WaitCommand, "Command should be a WaitCommand");
        WaitCommand cmd = (WaitCommand) result.getCommands().get(0);
        assertEquals(5, cmd.getDuration(), "Duration should be 5");
        assertEquals("sec", cmd.getTimeUnit(), "Time unit should be sec");
        assertEquals(5000, cmd.getDurationInMillis(), "Duration in ms should be 5000");
    }

    @Test
    public void testParseRepeatCommand() {
        ScriptNode result = parser.parse("repeat 3 times { lights on; wait 1 sec; lights off; }");

        assertEquals(1, result.getCommands().size(), "Script should have 1 command");
        assertTrue(result.getCommands().get(0) instanceof RepeatCommand, "Command should be a RepeatCommand");
        RepeatCommand cmd = (RepeatCommand) result.getCommands().get(0);
        assertEquals(3, cmd.getTimes(), "Repeat count should be 3");
        assertEquals(3, cmd.getCommands().size(), "Repeat should contain 3 inner commands");
        assertFalse(cmd.isTimeBased(), "Should not be time-based");
    }

    @Test
    public void testParseTransitionCommand() {
        ScriptNode result = parser.parse("transition \"red\" to \"blue\" over 5 seconds;");

        assertEquals(1, result.getCommands().size(), "Script should have 1 command");
        assertTrue(result.getCommands().get(0) instanceof TransitionCommand, "Command should be a TransitionCommand");
        TransitionCommand cmd = (TransitionCommand) result.getCommands().get(0);
        assertEquals("#FF0000", cmd.getFromColorValue(), "From color should be #FF0000");
        assertEquals("#0000FF", cmd.getToColorValue(), "To color should be #0000FF");
        assertEquals(5, cmd.getDuration(), "Duration should be 5");
        assertEquals("seconds", cmd.getTimeUnit(), "Time unit should be seconds");
    }

    @Test
    public void testParseVariableDeclaration() {
        ScriptNode result = parser.parse("var myColor = \"red\";");

        assertTrue(result.getCommands().isEmpty(), "Variable declaration doesn't add commands");
        Map<String, String> variables = parser.getVariables();
        assertTrue(variables.containsKey("myColor"), "Variable myColor should be defined");
        assertEquals("#FF0000", variables.get("myColor"), "myColor should be #FF0000");
    }

    @Test
    public void testParseSceneDefinition() {
        ScriptNode result = parser.parse(
                "define scene myScene {\n"
                + "  lights color \"red\";\n"
                + "  brightness 50;\n"
                + "}"
        );

        assertTrue(result.getCommands().isEmpty(), "Scene definition doesn't add commands to main script");
        Map<String, SceneCommand> scenes = parser.getScenes();
        assertTrue(scenes.containsKey("myScene"), "Scene myScene should be defined");
        assertEquals(2, scenes.get("myScene").getCommands().size(), "Scene should have 2 commands");
    }
}
