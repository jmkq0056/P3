package com.soft.p4.hueScriptLanguage.parser.strategy.single;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.all.BrightnessCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.parser.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Parses brightness commands in the format: light <id> brightness <level>;
 * Level must be between 0-100.
 */
public class LightBrightnessCommandParserStrategy implements CommandParserStrategy {

    private final String lightId;

    public LightBrightnessCommandParserStrategy(String lightId) {
        this.lightId = lightId;
    }

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();

        // Consume the "brightness" token
        context.consume(TokenType.BRIGHTNESS, "Expected 'brightness' after 'light " + lightId + "'");

        // Expect a number for brightness level
        if (context.match(TokenType.NUMBER)) {
            // Parse the brightness level (0-100)
            int level;
            try {
                level = Integer.parseInt(context.previous().getValue());
                if (level < 0 || level > 100) {
                    throw new ParserException("Brightness level must be between 0 and 100 at line "
                            + lineNumber);
                }
            } catch (NumberFormatException e) {
                throw new ParserException("Invalid number format at line " + lineNumber);
            }

            context.consume(TokenType.SEMICOLON, "Expected ';' after brightness level");
            scriptNode.addCommand(new BrightnessCommand(level, lightId, lineNumber));
        } else {
            throw new ParserException("Expected brightness level (0-100) at line "
                    + context.peek().getLineNumber());
        }
    }
}
