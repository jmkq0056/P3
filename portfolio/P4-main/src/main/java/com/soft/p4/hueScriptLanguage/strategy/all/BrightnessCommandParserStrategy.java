package com.soft.p4.hueScriptLanguage.strategy.all;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.all.BrightnessCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Parses brightness commands in the format: brightness <level>; where level is
 * an integer between 0-100.
 */
public class BrightnessCommandParserStrategy implements CommandParserStrategy {

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();

        // Parse brightness level
        if (context.match(TokenType.NUMBER)) {
            // Validate range (0-100)
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
            scriptNode.addCommand(new BrightnessCommand(level, lineNumber));
        } else {
            throw new ParserException("Expected brightness level (0-100) at line "
                    + context.peek().getLineNumber());
        }
    }
}
