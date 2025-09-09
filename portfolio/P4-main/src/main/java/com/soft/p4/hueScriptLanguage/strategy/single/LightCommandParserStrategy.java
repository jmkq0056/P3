package com.soft.p4.hueScriptLanguage.strategy.single;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.all.LightCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.parser.strategy.single.LightColorCommandParserStrategy;
import com.soft.p4.hueScriptLanguage.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Parses single light commands in the formats: - light <id> (on|off) - light
 * <id> color ... - light <id> brightness ... - light <id> transition ... ID can
 * be a number, string, or variable reference.
 */
public class LightCommandParserStrategy implements CommandParserStrategy {

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();

        // Parse light ID
        if (!context.match(TokenType.NUMBER) && !context.match(TokenType.STRING) && !context.match(TokenType.IDENTIFIER)) {
            throw new ParserException("Expected light ID after 'light' at line " + lineNumber);
        }

        String lightId = context.previous().getValue();
        if (context.previous().getType() == TokenType.STRING) {
            lightId = lightId.substring(1, lightId.length() - 1);
        }

        // Route to appropriate command parser
        if (context.peek().getType() == TokenType.COLOR) {
            new LightColorCommandParserStrategy(lightId).parse(context, scriptNode);
            return;
        }

        if (context.peek().getType() == TokenType.BRIGHTNESS) {
            new LightBrightnessCommandParserStrategy(lightId).parse(context, scriptNode);
            return;
        }

        if (context.peek().getType() == TokenType.TRANSITION) {
            new LightTransitionCommandParserStrategy(lightId).parse(context, scriptNode);
            return;
        }

        // Handle power state changes
        if (context.match(TokenType.ON)) {
            context.consume(TokenType.SEMICOLON, "Expected ';' after 'light " + lightId + " on'");
            scriptNode.addCommand(new LightCommand(LightCommand.Action.ON, lightId, lineNumber));
        } else if (context.match(TokenType.OFF)) {
            context.consume(TokenType.SEMICOLON, "Expected ';' after 'light " + lightId + " off'");
            scriptNode.addCommand(new LightCommand(LightCommand.Action.OFF, lightId, lineNumber));
        } else {
            throw new ParserException("Expected 'on', 'off', 'color', 'brightness', or 'transition' after 'light " + lightId + "' at line " + lineNumber);
        }
    }
}
