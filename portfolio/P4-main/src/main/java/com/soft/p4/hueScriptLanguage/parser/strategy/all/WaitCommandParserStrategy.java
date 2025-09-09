package com.soft.p4.hueScriptLanguage.parser.strategy.all;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.all.WaitCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.parser.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Parses wait commands in the format: wait <duration> [unit]; Units: ms, sec,
 * min, hr (defaults to ms if omitted)
 */
public class WaitCommandParserStrategy implements CommandParserStrategy {

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();

        // Parse duration value
        if (context.match(TokenType.NUMBER)) {
            int duration;
            try {
                duration = Integer.parseInt(context.previous().getValue());
                if (duration < 0) {
                    throw new ParserException("Wait duration must be a positive number at line " + lineNumber);
                }
            } catch (NumberFormatException e) {
                throw new ParserException("Invalid duration format at line " + lineNumber);
            }

            // Parse optional time unit
            String timeUnit = "";
            if (context.peek().getType() == TokenType.SEC
                    || context.peek().getType() == TokenType.MIN
                    || context.peek().getType() == TokenType.HR
                    || context.peek().getType() == TokenType.SECONDS
                    || context.peek().getType() == TokenType.MINUTES
                    || context.peek().getType() == TokenType.HOURS
                    || context.peek().getType() == TokenType.MS
                    || context.peek().getType() == TokenType.MILLISECONDS
                    || context.peek().getType() == TokenType.MILLISECOND) {

                timeUnit = context.peek().getValue();
                context.advance();
            }

            context.consume(TokenType.SEMICOLON, "Expected ';' after wait command");
            scriptNode.addCommand(new WaitCommand(duration, timeUnit, lineNumber));
        } else {
            throw new ParserException("Expected duration after 'wait' at line " + context.peek().getLineNumber());
        }
    }
}
