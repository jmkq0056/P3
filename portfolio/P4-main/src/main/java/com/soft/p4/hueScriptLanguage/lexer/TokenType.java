package com.soft.p4.hueScriptLanguage.lexer;

/**
 * Token types for the Hue script language. Organized by functional category to
 * improve maintainability and readability. Supports core light control, flow
 * control, variables, scenes, and time units.
 */
public enum TokenType {
    // Core light control
    LIGHTS, LIGHT, ON, OFF, BRIGHTNESS, COLOR,
    // Flow control
    WAIT, REPEAT, TIMES, FOR,
    // Color transitions
    TRANSITION, TO,
    // Variables and scenes
    VAR, ASSIGN, IDENTIFIER, SCENE, DEFINE,
    // Group operations
    GROUP,
    // Time units
    SEC, MIN, HR, // Short forms
    SECONDS, MINUTES, HOURS, // Plural
    SECOND, MINUTE, HOUR, // Singular
    MS, MILLISECONDS, MILLISECOND, // Milliseconds

    // Literals and delimiters
    NUMBER, STRING,
    SEMICOLON, LEFT_BRACE, RIGHT_BRACE,
    // Special tokens
    WHITESPACE, COMMENT, UNKNOWN, EOF
}
