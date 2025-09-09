package com.soft.p4.hueScriptLanguage.parser.strategy.all;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.all.ColorCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.LightCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.parser.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Routes light commands to appropriate handlers: - lights color <value> ->
 * LightsColorCommandParserStrategy - light <id> on|off ->
 * parseSpecificLightCommand - lights on|off -> LightsOnOffCommandParserStrategy
 */
public class LightsCommandParserStrategy implements CommandParserStrategy {

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        if (context.peek().getType() == TokenType.COLOR) {
            new LightsColorCommandParserStrategy().parse(context, scriptNode);
            return;
        }

        if (context.previous().getType() == TokenType.LIGHT) {
            parseSpecificLightCommand(context, scriptNode);
            return;
        }

        new LightsOnOffCommandParserStrategy().parse(context, scriptNode);
    }

    private void parseSpecificLightCommand(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();

        // Parse light ID
        if (!context.match(TokenType.NUMBER) && !context.match(TokenType.STRING) && !context.match(TokenType.IDENTIFIER)) {
            throw new ParserException("Expected light ID after 'light' at line " + lineNumber);
        }

        String lightId = context.previous().getValue();
        if (context.previous().getType() == TokenType.STRING) {
            lightId = lightId.substring(1, lightId.length() - 1);
        }

        // Parse power state
        if (context.match(TokenType.ON)) {
            context.consume(TokenType.SEMICOLON, "Expected ';' after 'light " + lightId + " on'");
            scriptNode.addCommand(new LightCommand(LightCommand.Action.ON, lightId, lineNumber));
        } else if (context.match(TokenType.OFF)) {
            context.consume(TokenType.SEMICOLON, "Expected ';' after 'light " + lightId + " off'");
            scriptNode.addCommand(new LightCommand(LightCommand.Action.OFF, lightId, lineNumber));
        } else {
            throw new ParserException("Expected 'on' or 'off' after 'light " + lightId + "' at line " + lineNumber);
        }
    }
}

/**
 * Parses color commands in the format: lights color <value>; Value can be a hex
 * code, predefined color name, or variable reference.
 */
class LightsColorCommandParserStrategy implements CommandParserStrategy {

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();
        context.consume(TokenType.COLOR, "Expected 'color' after 'lights'");

        // Parse color value
        if (context.match(TokenType.STRING)) {
            String colorValue = context.previous().getValue();
            colorValue = colorValue.substring(1, colorValue.length() - 1);
            String resolvedColor = context.validateAndResolveColor(colorValue, lineNumber);

            context.consume(TokenType.SEMICOLON, "Expected ';' after color value");
            scriptNode.addCommand(new ColorCommand(resolvedColor, lineNumber));
        } else if (context.match(TokenType.IDENTIFIER)) {
            String variableName = context.previous().getValue();
            if (!context.getVariables().containsKey(variableName)) {
                throw new ParserException("Undefined variable '" + variableName + "' at line " + lineNumber);
            }

            String colorValue = context.getVariables().get(variableName);
            context.consume(TokenType.SEMICOLON, "Expected ';' after color value");
            scriptNode.addCommand(new ColorCommand(colorValue, lineNumber));
        } else {
            throw new ParserException("Expected color value (as string or variable) at line "
                    + context.peek().getLineNumber());
        }
    }
}

/**
 * Parses global power commands in the format: lights (on|off);
 */
class LightsOnOffCommandParserStrategy implements CommandParserStrategy {

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();

        if (context.match(TokenType.ON)) {
            context.consume(TokenType.SEMICOLON, "Expected ';' after 'lights on'");
            scriptNode.addCommand(new LightCommand(LightCommand.Action.ON, lineNumber));
        } else if (context.match(TokenType.OFF)) {
            context.consume(TokenType.SEMICOLON, "Expected ';' after 'lights off'");
            scriptNode.addCommand(new LightCommand(LightCommand.Action.OFF, lineNumber));
        } else {
            throw new ParserException("Expected 'on' or 'off' after 'lights' at line "
                    + context.peek().getLineNumber());
        }
    }
}
