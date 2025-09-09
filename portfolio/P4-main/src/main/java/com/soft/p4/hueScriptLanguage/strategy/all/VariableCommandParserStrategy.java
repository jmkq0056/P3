// 2. Update VariableCommandParserStrategy.java to correctly pass variable name
package com.soft.p4.hueScriptLanguage.strategy.all;

import java.util.Map;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Parses variable declarations in two formats: 1. Color variables: var <name> =
 * <color>; 2. Transition variables: var <name> = transition ...; Colors can be
 * hex codes (#RRGGBB) or predefined names.
 */
public class VariableCommandParserStrategy implements CommandParserStrategy {

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();
        Map<String, String> variables = context.getVariables();

        // Parse variable name
        if (!context.match(TokenType.IDENTIFIER)) {
            throw new ParserException("Expected variable name at line " + lineNumber);
        }

        String variableName = context.previous().getValue();

        // Parse assignment
        context.consume(TokenType.ASSIGN, "Expected '=' after variable name");

        // Handle transition variables
        if (context.peek().getType() == TokenType.TRANSITION
                || (context.peek().getType() == TokenType.IDENTIFIER
                && context.peek().getValue().equalsIgnoreCase("transition"))) {
            context.advance();
            TransitionVariableCommandParserStrategy transitionStrategy = new TransitionVariableCommandParserStrategy();
            transitionStrategy.setVariableName(variableName);
            transitionStrategy.parse(context, scriptNode);
            return;
        }

        // Parse color value
        if (!context.match(TokenType.STRING)) {
            throw new ParserException("Expected string value for color variable at line " + lineNumber);
        }

        String colorValue = context.previous().getValue();
        colorValue = colorValue.substring(1, colorValue.length() - 1);

        Map<String, String> predefinedColors = context.getPredefinedColors();

        // Resolve color value
        if (predefinedColors.containsKey(colorValue.toLowerCase())) {
            colorValue = predefinedColors.get(colorValue.toLowerCase());
        } else if (colorValue.startsWith("#")) {
            if (!colorValue.matches("^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$")) {
                throw new ParserException("Invalid hex color code: " + colorValue + " at line " + lineNumber);
            }
        } else {
            throw new ParserException("Invalid color: " + colorValue + " at line " + lineNumber
                    + ". Use predefined color names or hex codes (#RRGGBB)");
        }

        variables.put(variableName, colorValue);
        context.consume(TokenType.SEMICOLON, "Expected ';' after variable declaration");
    }
}
