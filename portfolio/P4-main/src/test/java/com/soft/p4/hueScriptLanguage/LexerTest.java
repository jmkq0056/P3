package com.soft.p4.hueScriptLanguage;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import org.junit.jupiter.api.Test;

import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.lexer.Lexer;
import com.soft.p4.hueScriptLanguage.lexer.Token;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Test suite for HueScript lexical analysis. Validates tokenization, whitespace
 * handling, and position tracking.
 */
public class LexerTest {

    private Lexer lexer = new Lexer();

    @Test
    public void testTokenizeEmptyString() {
        List<Token> tokens = lexer.tokenize("");

        // Should have just the EOF token
        assertEquals(1, tokens.size(), "Empty string should yield only EOF token");
        assertEquals(TokenType.EOF, tokens.get(0).getType(), "Token should be EOF");
    }

    @Test
    public void testTokenizeLightsOnCommand() {
        List<Token> tokens = lexer.tokenize("lights on;");

        // Expect: LIGHTS, ON, SEMICOLON, EOF
        assertEquals(4, tokens.size(), "Should have 4 tokens including EOF");
        assertEquals(TokenType.LIGHTS, tokens.get(0).getType());
        assertEquals(TokenType.ON, tokens.get(1).getType());
        assertEquals(TokenType.SEMICOLON, tokens.get(2).getType());
        assertEquals(TokenType.EOF, tokens.get(3).getType());
    }

    @Test
    public void testTokenizeWithWhitespace() {
        List<Token> tokens = lexer.tokenize("  lights  on ;  ");

        // Whitespace should be ignored
        assertEquals(4, tokens.size(), "Should have 4 tokens including EOF");
        assertEquals(TokenType.LIGHTS, tokens.get(0).getType());
        assertEquals(TokenType.ON, tokens.get(1).getType());
        assertEquals(TokenType.SEMICOLON, tokens.get(2).getType());
    }

    @Test
    public void testTokenizeWithComments() {
        List<Token> tokens = lexer.tokenize("lights on; // Turn on the lights");

        // Comments should be ignored
        assertEquals(4, tokens.size(), "Should have 4 tokens including EOF");
        assertEquals(TokenType.LIGHTS, tokens.get(0).getType());
        assertEquals(TokenType.ON, tokens.get(1).getType());
        assertEquals(TokenType.SEMICOLON, tokens.get(2).getType());
    }

    @Test
    public void testTokenizeMultilineScript() {
        String script
                = "// Turn on lights\n"
                + "lights on;\n"
                + "\n"
                + // Empty line
                "// Set brightness\n"
                + "brightness 75;";

        List<Token> tokens = lexer.tokenize(script);

        // Expect: LIGHTS, ON, SEMICOLON, BRIGHTNESS, NUMBER(75), SEMICOLON, EOF
        assertEquals(7, tokens.size(), "Should have 7 tokens including EOF");
        assertEquals(TokenType.LIGHTS, tokens.get(0).getType());
        assertEquals(TokenType.ON, tokens.get(1).getType());
        assertEquals(TokenType.SEMICOLON, tokens.get(2).getType());
        assertEquals(TokenType.BRIGHTNESS, tokens.get(3).getType());
        assertEquals(TokenType.NUMBER, tokens.get(4).getType());
        assertEquals("75", tokens.get(4).getValue());
        assertEquals(TokenType.SEMICOLON, tokens.get(5).getType());
    }

    @Test
    public void testTokenizeStringLiteral() {
        List<Token> tokens = lexer.tokenize("lights color \"red\";");

        // Expect: LIGHTS, COLOR, STRING("red"), SEMICOLON, EOF
        assertEquals(5, tokens.size(), "Should have 5 tokens including EOF");
        assertEquals(TokenType.LIGHTS, tokens.get(0).getType());
        assertEquals(TokenType.COLOR, tokens.get(1).getType());
        assertEquals(TokenType.STRING, tokens.get(2).getType());
        assertEquals("\"red\"", tokens.get(2).getValue());
        assertEquals(TokenType.SEMICOLON, tokens.get(3).getType());
    }

    @Test
    public void testTokenizeRepeatCommand() {
        List<Token> tokens = lexer.tokenize("repeat 5 times { lights on; }");

        // Expect: REPEAT, NUMBER(5), TIMES, LEFT_BRACE, LIGHTS, ON, SEMICOLON, RIGHT_BRACE, EOF
        assertEquals(9, tokens.size(), "Should have 9 tokens including EOF");
        assertEquals(TokenType.REPEAT, tokens.get(0).getType());
        assertEquals(TokenType.NUMBER, tokens.get(1).getType());
        assertEquals("5", tokens.get(1).getValue());
        assertEquals(TokenType.TIMES, tokens.get(2).getType());
        assertEquals(TokenType.LEFT_BRACE, tokens.get(3).getType());
        assertEquals(TokenType.LIGHTS, tokens.get(4).getType());
        assertEquals(TokenType.ON, tokens.get(5).getType());
        assertEquals(TokenType.SEMICOLON, tokens.get(6).getType());
        assertEquals(TokenType.RIGHT_BRACE, tokens.get(7).getType());
    }

    @Test
    public void testTokenizeTimeUnits() {
        // Test each time unit
        List<Token> tokens = lexer.tokenize("wait 5 sec; wait 2 min; wait 1 hr; wait 100 ms;");

        // Check the time units
        assertEquals(TokenType.SEC, tokens.get(2).getType());
        assertEquals(TokenType.MIN, tokens.get(6).getType());
        assertEquals(TokenType.HR, tokens.get(10).getType());
        assertEquals(TokenType.MS, tokens.get(14).getType());
    }

    @Test
    public void testTokenizeSceneDefinition() {
        List<Token> tokens = lexer.tokenize("define scene myScene { brightness 50; }");

        // Expect: DEFINE, SCENE, IDENTIFIER(myScene), LEFT_BRACE, BRIGHTNESS, NUMBER(50), SEMICOLON, RIGHT_BRACE, EOF
        assertEquals(9, tokens.size(), "Should have 9 tokens including EOF");
        assertEquals(TokenType.DEFINE, tokens.get(0).getType());
        assertEquals(TokenType.SCENE, tokens.get(1).getType());
        assertEquals(TokenType.IDENTIFIER, tokens.get(2).getType());
        assertEquals("myScene", tokens.get(2).getValue());
    }

    @Test
    public void testTokenizeSceneInvocation() {
        List<Token> tokens = lexer.tokenize("scene myScene;");

        // Expect: SCENE, IDENTIFIER(myScene), SEMICOLON, EOF
        assertEquals(4, tokens.size(), "Should have 4 tokens including EOF");
        assertEquals(TokenType.SCENE, tokens.get(0).getType());
        assertEquals(TokenType.IDENTIFIER, tokens.get(1).getType());
        assertEquals("myScene", tokens.get(1).getValue());
        assertEquals(TokenType.SEMICOLON, tokens.get(2).getType());
    }

    @Test
    public void testTokenizeVariableDeclaration() {
        List<Token> tokens = lexer.tokenize("var myColor = \"red\";");

        // Expect: VAR, IDENTIFIER(myColor), ASSIGN, STRING("red"), SEMICOLON, EOF
        assertEquals(6, tokens.size(), "Should have 6 tokens including EOF");
        assertEquals(TokenType.VAR, tokens.get(0).getType());
        assertEquals(TokenType.IDENTIFIER, tokens.get(1).getType());
        assertEquals("myColor", tokens.get(1).getValue());
        assertEquals(TokenType.ASSIGN, tokens.get(2).getType());
        assertEquals(TokenType.STRING, tokens.get(3).getType());
        assertEquals("\"red\"", tokens.get(3).getValue());
        assertEquals(TokenType.SEMICOLON, tokens.get(4).getType());
    }

    @Test
    public void testTokenizeTransitionCommand() {
        List<Token> tokens = lexer.tokenize("transition \"red\" to \"blue\" over 5 seconds;");

        // Expect: TRANSITION, STRING("red"), TO, STRING("blue"), OVER, NUMBER(5), SECONDS, SEMICOLON, EOF
        assertEquals(9, tokens.size(), "Should have 9 tokens including EOF");
        assertEquals(TokenType.TRANSITION, tokens.get(0).getType());
        assertEquals(TokenType.STRING, tokens.get(1).getType());
        assertEquals("\"red\"", tokens.get(1).getValue());
        assertEquals(TokenType.TO, tokens.get(2).getType());
        assertEquals(TokenType.STRING, tokens.get(3).getType());
        assertEquals("\"blue\"", tokens.get(3).getValue());
        assertEquals("over", tokens.get(4).getValue());
        assertEquals(TokenType.NUMBER, tokens.get(5).getType());
        assertEquals("5", tokens.get(5).getValue());
        assertEquals(TokenType.SECONDS, tokens.get(6).getType());
        assertEquals(TokenType.SEMICOLON, tokens.get(7).getType());
    }

    @Test
    public void testInvalidToken() {
        // Unexpected character
        assertThrows(ParserException.class, () -> lexer.tokenize("lights @on;"),
                "Should throw ParserException for unexpected character");
    }

    @Test
    public void testLineAndPositionTracking() {
        List<Token> tokens = lexer.tokenize("lights on;\nbrightness 100;");

        // First line tokens
        assertEquals(1, tokens.get(0).getLineNumber(), "First token should be on line 1");
        assertEquals(1, tokens.get(0).getPosition(), "Position should start at 1");
        assertEquals(1, tokens.get(1).getLineNumber(), "Second token should be on line 1");
        assertEquals(8, tokens.get(1).getPosition(), "ON token should be at position 8");

        // Second line tokens
        assertEquals(2, tokens.get(3).getLineNumber(), "BRIGHTNESS token should be on line 2");
        assertEquals(1, tokens.get(3).getPosition(), "BRIGHTNESS token should be at position 1");
    }
}
