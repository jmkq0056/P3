package com.soft.p4.hueScriptLanguage.parser;

import java.util.List;
import java.util.Map;

import com.soft.p4.hueScriptLanguage.ast.command.all.SceneCommand;
import com.soft.p4.hueScriptLanguage.lexer.Token;

/**
 * Maintains parser state and provides token handling utilities during script
 * parsing. Acts as a facade to the main parser, encapsulating token stream
 * access and symbol resolution. Used by command parsing strategies to maintain
 * consistent state.
 */
public class ParserContext {

    private final List<Token> tokens;
    private final Map<String, String> variables;
    private final Map<String, SceneCommand> scenes;
    private final Map<String, String> predefinedColors;
    private final HueScriptParser parser;
    private final Map<String, List<String>> groups;

    /**
     * Creates a new parsing context with all necessary state.
     *
     * @param tokens Token stream being parsed
     * @param groups Light group definitions
     * @param variables Variable bindings
     * @param scenes Scene definitions
     * @param predefinedColors Standard color palette
     * @param parser Reference to main parser for token handling
     */
    public ParserContext(
            List<Token> tokens,
            Map<String, List<String>> groups,
            Map<String, String> variables,
            Map<String, SceneCommand> scenes,
            Map<String, String> predefinedColors,
            HueScriptParser parser) {
        this.tokens = tokens;
        this.groups = groups;
        this.variables = variables;
        this.scenes = scenes;
        this.predefinedColors = predefinedColors;
        this.parser = parser;
    }

    // State accessors
    public List<Token> getTokens() {
        return tokens;
    }

    public Map<String, String> getVariables() {
        return variables;
    }

    public Map<String, SceneCommand> getScenes() {
        return scenes;
    }

    public Map<String, String> getPredefinedColors() {
        return predefinedColors;
    }

    // Token handling delegates
    public boolean isAtEnd() {
        return parser.isAtEnd();
    }

    public Token peek() {
        return parser.peek();
    }

    public Token previous() {
        return parser.previous();
    }

    public Token advance() {
        return parser.advance();
    }

    public boolean match(com.soft.p4.hueScriptLanguage.lexer.TokenType type) {
        return parser.match(type);
    }

    public Token consume(com.soft.p4.hueScriptLanguage.lexer.TokenType type, String errorMessage) {
        return parser.consume(type, errorMessage);
    }

    public void skipToSemicolon() {
        parser.skipToSemicolon();
    }

    public boolean isInsideLoop() {
        return parser.isInsideLoop();
    }

    public void setInsideLoop(boolean insideLoop) {
        parser.setInsideLoop(insideLoop);
    }

    public String validateAndResolveColor(String colorValue, int lineNumber) {
        return parser.validateAndResolveColor(colorValue, lineNumber);
    }
}
