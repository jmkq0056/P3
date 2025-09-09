package com.soft.p4.hueScriptLanguage.parser.strategy.single;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.all.ColorCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.parser.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Parses color commands in the format: light <id> color <value>; Value can be a
 * hex code, predefined name, or variable reference.
 */
public class LightColorCommandParserStrategy implements CommandParserStrategy {

    private final String lightId;

    public LightColorCommandParserStrategy(String lightId) {
        this.lightId = lightId;
    }

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();
        context.consume(TokenType.COLOR, "Expected 'color' after 'light " + lightId + "'");

        // Parse color value
        if (context.match(TokenType.STRING)) {
            String colorValue = context.previous().getValue();
            colorValue = colorValue.substring(1, colorValue.length() - 1);
            String resolvedColor = context.validateAndResolveColor(colorValue, lineNumber);

            context.consume(TokenType.SEMICOLON, "Expected ';' after color value");
            scriptNode.addCommand(new ColorCommand(resolvedColor, lightId, lineNumber));
        } else if (context.match(TokenType.IDENTIFIER)) {
            String variableName = context.previous().getValue();
            if (!context.getVariables().containsKey(variableName)) {
                throw new ParserException("Undefined variable '" + variableName + "' at line " + lineNumber);
            }
            String colorValue = context.getVariables().get(variableName);

            context.consume(TokenType.SEMICOLON, "Expected ';' after color value");
            scriptNode.addCommand(new ColorCommand(colorValue, lightId, lineNumber));
        } else {
            throw new ParserException("Expected color value (as string or variable) at line "
                    + context.peek().getLineNumber());
        }
    }
}
