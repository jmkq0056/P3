// TokenType.java
package com.soft.p4.hueScriptLanguage.lexer;

/**
 * Represents a lexical token with type, value, and source position information.
 * Immutable class used throughout the parsing pipeline for script analysis.
 * Tracks line and column position for error reporting.
 */
public class Token {

    private final TokenType type;     // Type of the token
    private final String value;       // Actual text from source
    private final int lineNumber;     // 1-based line number
    private final int position;       // 1-based position in line

    /**
     * Creates a new token with source position information.
     *
     * @param type Token classification
     * @param value Raw text from source
     * @param lineNumber Line number in source (1-based)
     * @param position Character position in line (1-based)
     */
    public Token(TokenType type, String value, int lineNumber, int position) {
        this.type = type;
        this.value = value;
        this.lineNumber = lineNumber;
        this.position = position;
    }

    public TokenType getType() {
        return type;
    }

    public String getValue() {
        return value;
    }

    public int getLineNumber() {
        return lineNumber;
    }

    public int getPosition() {
        return position;
    }

    @Override
    public String toString() {
        return String.format("%s('%s') at line %d, pos %d",
                type, value, lineNumber, position);
    }
}
