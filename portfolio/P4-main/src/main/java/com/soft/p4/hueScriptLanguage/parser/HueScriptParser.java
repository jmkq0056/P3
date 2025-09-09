package com.soft.p4.hueScriptLanguage.parser;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Component;

import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.all.SceneCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.lexer.Lexer;
import com.soft.p4.hueScriptLanguage.lexer.Token;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;
import com.soft.p4.hueScriptLanguage.parser.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.parser.strategy.all.BrightnessCommandParserStrategy;
import com.soft.p4.hueScriptLanguage.parser.strategy.all.LightsCommandParserStrategy;
import com.soft.p4.hueScriptLanguage.parser.strategy.all.RepeatCommandParserStrategy;
import com.soft.p4.hueScriptLanguage.parser.strategy.all.SceneDefinitionParserStrategy;
import com.soft.p4.hueScriptLanguage.parser.strategy.all.SceneInvocationParserStrategy;
import com.soft.p4.hueScriptLanguage.parser.strategy.all.TransitionCommandParserStrategy;
import com.soft.p4.hueScriptLanguage.parser.strategy.all.VariableCommandParserStrategy;
import com.soft.p4.hueScriptLanguage.parser.strategy.all.VariableInvocationParserStrategy;
import com.soft.p4.hueScriptLanguage.parser.strategy.all.WaitCommandParserStrategy;
import com.soft.p4.hueScriptLanguage.parser.strategy.group.GroupCommandParserStrategy;
import com.soft.p4.hueScriptLanguage.parser.strategy.single.LightCommandParserStrategy;

/**
 * Core parser for the Hue script language. Handles token processing, command
 * parsing, and AST construction using a strategy pattern for different command
 * types. Maintains state for variables, scenes, and light groups during
 * parsing.
 */
@Component
public class HueScriptParser {

    private final Lexer lexer = new Lexer();
    private List<Token> tokens;
    private int currentTokenIndex = 0;
    private boolean insideLoop = false;

    private static final Map<String, String> PREDEFINED_COLORS = new HashMap<>();
    private final Map<String, String> variables = new HashMap<>();
    private final Map<String, SceneCommand> scenes = new HashMap<>();
    private final Map<TokenType, CommandParserStrategy> parserStrategies = new HashMap<>();
    private final Map<String, List<String>> groups = new HashMap<>();

    static {
        // Standard color palette
        PREDEFINED_COLORS.put("red", "#FF0000");
        PREDEFINED_COLORS.put("green", "#00FF00");
        PREDEFINED_COLORS.put("blue", "#0000FF");
        PREDEFINED_COLORS.put("yellow", "#FFFF00");
        PREDEFINED_COLORS.put("orange", "#FFA500");
        PREDEFINED_COLORS.put("purple", "#800080");
        PREDEFINED_COLORS.put("pink", "#FFC0CB");
        PREDEFINED_COLORS.put("white", "#FFFFFF");
        PREDEFINED_COLORS.put("warm", "#FF9900");
        PREDEFINED_COLORS.put("cool", "#F5F5DC");
    }

    public HueScriptParser() {
        initializeStrategies();
    }

    private void initializeStrategies() {
        parserStrategies.put(TokenType.VAR, new VariableCommandParserStrategy());
        parserStrategies.put(TokenType.DEFINE, new SceneDefinitionParserStrategy());
        parserStrategies.put(TokenType.SCENE, new SceneInvocationParserStrategy());
        parserStrategies.put(TokenType.LIGHT, new LightCommandParserStrategy());
        parserStrategies.put(TokenType.LIGHTS, new LightsCommandParserStrategy());
        parserStrategies.put(TokenType.BRIGHTNESS, new BrightnessCommandParserStrategy());
        parserStrategies.put(TokenType.WAIT, new WaitCommandParserStrategy());
        parserStrategies.put(TokenType.REPEAT, new RepeatCommandParserStrategy());
        parserStrategies.put(TokenType.TRANSITION, new TransitionCommandParserStrategy());
        parserStrategies.put(TokenType.GROUP, new GroupCommandParserStrategy());
        parserStrategies.put(TokenType.IDENTIFIER, new VariableInvocationParserStrategy());
    }

    public Map<String, String> getVariables() {
        return new HashMap<>(variables);
    }

    public void setExistingVariables(Map<String, String> existingVariables) {
        if (existingVariables != null) {
            this.variables.putAll(existingVariables);
        }
    }

    /**
     * Loads pre-existing scenes for reference resolution during parsing
     */
    public void setExistingScenes(Map<String, SceneCommand> existingScenes) {
        if (existingScenes != null) {
            this.scenes.putAll(existingScenes);
        }
    }

    public Map<String, SceneCommand> getScenes() {
        return new HashMap<>(scenes);
    }

    /**
     * Parses a Hue script into an AST. Handles variable resolution, scene
     * definitions, and command sequencing. Validates syntax and maintains
     * parsing context.
     *
     * @param scriptContent Raw script text to parse
     * @return Root node of the parsed AST
     * @throws ParserException on syntax errors or invalid commands
     */
    public ScriptNode parse(String scriptContent) {
        // Reset parser state
        tokens = lexer.tokenize(scriptContent);
        currentTokenIndex = 0;
        variables.clear();
        scenes.clear();
        insideLoop = false;

        ScriptNode scriptNode = new ScriptNode();

        // Initialize parsing context with current state
        ParserContext context = new ParserContext(
                tokens,
                groups,
                variables,
                scenes,
                PREDEFINED_COLORS,
                this
        );

        // Process tokens sequentially
        while (!isAtEnd()) {
            try {
                TokenType tokenType = peek().getType();
                CommandParserStrategy strategy = parserStrategies.get(tokenType);

                if (strategy != null) {
                    advance(); // Consume token
                    strategy.parse(context, scriptNode);
                } else if (tokenType == TokenType.FOR) {
                    throw new ParserException("Unexpected 'for' keyword outside of repeat context at line "
                            + peek().getLineNumber());
                } else {
                    throw new ParserException("Unexpected token: " + peek().getValue()
                            + " at line " + peek().getLineNumber());
                }
            } catch (ParserException e) {
                // Skip to next statement on error
                skipToSemicolon();
                throw e;
            }
        }

        return scriptNode;
    }

    // Token handling utilities used by parser strategies
    public boolean isAtEnd() {
        return peek().getType() == TokenType.EOF;
    }

    public Token peek() {
        return tokens.get(currentTokenIndex);
    }

    public Token previous() {
        return tokens.get(currentTokenIndex - 1);
    }

    public Token advance() {
        if (!isAtEnd()) {
            currentTokenIndex++;
        }
        return previous();
    }

    public boolean match(TokenType type) {
        if (peek().getType() != type) {
            return false;
        }
        advance();
        return true;
    }

    public Token consume(TokenType type, String errorMessage) {
        if (peek().getType() == type) {
            return advance();
        }
        throw new ParserException(errorMessage + " at line " + peek().getLineNumber());
    }

    public void skipToSemicolon() {
        while (!isAtEnd() && peek().getType() != TokenType.SEMICOLON) {
            advance();
        }

        if (!isAtEnd()) {
            advance(); // Skip the semicolon too
        }
    }

    public void setInsideLoop(boolean insideLoop) {
        this.insideLoop = insideLoop;
    }

    public boolean isInsideLoop() {
        return insideLoop;
    }

    /**
     * Validates and resolves color values from variables, predefined names, or
     * hex codes. Supports #RRGGBB format and named colors.
     *
     * @param colorValue Color value to validate/resolve
     * @param lineNumber Source line for error reporting
     * @return Resolved hex color code
     * @throws ParserException if color format is invalid
     */
    public String validateAndResolveColor(String colorValue, int lineNumber) {
        // Check variable reference
        if (variables.containsKey(colorValue)) {
            return variables.get(colorValue);
        } // Check predefined color name
        else if (PREDEFINED_COLORS.containsKey(colorValue.toLowerCase())) {
            return PREDEFINED_COLORS.get(colorValue.toLowerCase());
        } // Validate hex color format
        else if (colorValue.startsWith("#")) {
            if (!colorValue.matches("^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$")) {
                throw new ParserException("Invalid hex color code: " + colorValue + " at line " + lineNumber);
            }
            return colorValue;
        } else {
            throw new ParserException("Invalid color: " + colorValue + " at line " + lineNumber
                    + ". Use predefined color names, variables, or hex codes (#RRGGBB)");
        }
    }

    public Map<String, List<String>> getGroups() {
        return new HashMap<>(groups);
    }

    public void setExistingGroups(Map<String, List<String>> existingGroups) {
        if (existingGroups != null) {
            this.groups.putAll(existingGroups);
        }
    }
}
