package com.soft.p4.hueScriptLanguage.strategy.all;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.all.TransitionCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Parses color transitions in the format: transition <from-color> to <to-color>
 * (over|in) <duration> <unit>; Colors can be hex values or variable references.
 * Units: ms, sec, min, hr
 */
public class TransitionCommandParserStrategy implements CommandParserStrategy {

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();
        String fromColorValue;
        String resolvedFromColor;

        // Parse source color (literal or variable)
        if (context.match(TokenType.STRING)) {
            fromColorValue = context.previous().getValue();
            fromColorValue = fromColorValue.substring(1, fromColorValue.length() - 1);
            resolvedFromColor = context.validateAndResolveColor(fromColorValue, lineNumber);
        } else if (context.match(TokenType.IDENTIFIER)) {
            String variableName = context.previous().getValue();
            if (!context.getVariables().containsKey(variableName)) {
                throw new ParserException("Undefined variable '" + variableName + "' at line " + lineNumber);
            }
            resolvedFromColor = context.getVariables().get(variableName);
        } else {
            throw new ParserException("Expected color value (as string or variable) after 'transition' at line " + lineNumber);
        }

        // Expect "to" keyword
        context.consume(TokenType.TO, "Expected 'to' after from-color in transition command");

        String toColorValue;
        String resolvedToColor;

        // Parse "to" color - can be string literal or variable reference
        if (context.match(TokenType.STRING)) {
            // Case 1: Direct string value
            toColorValue = context.previous().getValue();
            // Remove quotes from the string
            toColorValue = toColorValue.substring(1, toColorValue.length() - 1);
            // Validate and resolve the to color
            resolvedToColor = context.validateAndResolveColor(toColorValue, lineNumber);
        } else if (context.match(TokenType.IDENTIFIER)) {
            // Case 2: Variable reference
            String variableName = context.previous().getValue();
            // Check if variable exists
            if (!context.getVariables().containsKey(variableName)) {
                throw new ParserException("Undefined variable '" + variableName + "' at line " + lineNumber);
            }
            // Get the actual color value from the variable
            resolvedToColor = context.getVariables().get(variableName);
        } else {
            throw new ParserException("Expected color value (as string or variable) after 'to' at line " + lineNumber);
        }

        // Expect "over" or "in" keyword
        if (!(context.peek().getValue().equalsIgnoreCase("over")
                || context.peek().getValue().equalsIgnoreCase("in"))) {
            throw new ParserException("Expected 'over' or 'in' after to-color in transition command at line " + lineNumber);
        }
        context.advance(); // Consume "over" or "in"

        // Parse the duration
        if (!context.match(TokenType.NUMBER)) {
            throw new ParserException("Expected number for transition duration at line " + lineNumber);
        }

        int duration;
        try {
            duration = Integer.parseInt(context.previous().getValue());
            if (duration <= 0) {
                throw new ParserException("Transition duration must be a positive number at line " + lineNumber);
            }
        } catch (NumberFormatException e) {
            throw new ParserException("Invalid duration format at line " + lineNumber);
        }

        // Check for time unit
        String timeUnit = "";
        if (context.peek().getType() == TokenType.SEC
                || context.peek().getType() == TokenType.MIN
                || context.peek().getType() == TokenType.HR
                || context.peek().getType() == TokenType.SECONDS
                || context.peek().getType() == TokenType.MINUTES
                || context.peek().getType() == TokenType.HOURS
                || context.peek().getType() == TokenType.MS
                || context.peek().getType() == TokenType.MILLISECONDS
                || context.peek().getType() == TokenType.MILLISECOND
                || context.peek().getType() == TokenType.SECOND
                || context.peek().getType() == TokenType.MINUTE
                || context.peek().getType() == TokenType.HOUR) {

            // Get the time unit value and advance
            timeUnit = context.peek().getValue();
            context.advance();
        } else {
            throw new ParserException("Expected time unit (sec/min/hr/ms) after transition duration at line " + lineNumber);
        }

        context.consume(TokenType.SEMICOLON, "Expected ';' after transition command");
        scriptNode.addCommand(new TransitionCommand(resolvedFromColor, resolvedToColor, duration, timeUnit, lineNumber));
    }
}
