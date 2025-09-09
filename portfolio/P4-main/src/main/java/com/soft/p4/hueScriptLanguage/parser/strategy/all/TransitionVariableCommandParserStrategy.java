// 1. First, fix the TransitionVariableCommandParserStrategy.java
package com.soft.p4.hueScriptLanguage.parser.strategy.all;

import java.util.Map;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.parser.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Parses transition variable declarations in the format: var <name> =
 * transition <from-color> to <to-color> (over|in) <duration> <unit>; Colors can
 * be hex values or variable references. Stores transitions as JSON for runtime
 * interpretation.
 */
public class TransitionVariableCommandParserStrategy implements CommandParserStrategy {

    private String variableName; // Set by VariableCommandParserStrategy before parsing

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();
        Map<String, String> variables = context.getVariables();

        // Parse source color
        String fromColorValue;
        String resolvedFromColor;

        if (context.match(TokenType.STRING)) {
            fromColorValue = context.previous().getValue();
            fromColorValue = fromColorValue.substring(1, fromColorValue.length() - 1);
            resolvedFromColor = context.validateAndResolveColor(fromColorValue, lineNumber);
        } else if (context.match(TokenType.IDENTIFIER)) {
            String colorVarName = context.previous().getValue();
            if (!variables.containsKey(colorVarName)) {
                throw new ParserException("Undefined variable '" + colorVarName + "' at line " + lineNumber);
            }
            resolvedFromColor = variables.get(colorVarName);
        } else {
            throw new ParserException("Expected color value (as string or variable) after 'transition' at line " + lineNumber);
        }

        // Parse target color and duration
        context.consume(TokenType.TO, "Expected 'to' after from-color in transition variable declaration");

        String toColorValue;
        String resolvedToColor;

        // Parse "to" color
        if (context.match(TokenType.STRING)) {
            // Direct string value
            toColorValue = context.previous().getValue();
            toColorValue = toColorValue.substring(1, toColorValue.length() - 1);
            resolvedToColor = context.validateAndResolveColor(toColorValue, lineNumber);
        } else if (context.match(TokenType.IDENTIFIER)) {
            // Variable reference
            String colorVarName = context.previous().getValue();
            if (!variables.containsKey(colorVarName)) {
                throw new ParserException("Undefined variable '" + colorVarName + "' at line " + lineNumber);
            }
            resolvedToColor = variables.get(colorVarName);
        } else {
            throw new ParserException("Expected color value (as string or variable) after 'to' at line " + lineNumber);
        }

        // Expect "over" or "in" keyword
        if (!(context.peek().getValue().equalsIgnoreCase("over")
                || context.peek().getValue().equalsIgnoreCase("in"))) {
            throw new ParserException("Expected 'over' or 'in' after to-color in transition variable declaration at line " + lineNumber);
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

            timeUnit = context.peek().getValue();
            context.advance();
        } else {
            throw new ParserException("Expected time unit (sec/min/hr/ms) after transition duration at line " + lineNumber);
        }

        // Store transition definition
        String transitionDefinition = String.format(
                "{\"type\":\"transition\",\"fromColor\":\"%s\",\"toColor\":\"%s\",\"duration\":%d,\"timeUnit\":\"%s\"}",
                resolvedFromColor, resolvedToColor, duration, timeUnit);

        variables.put(variableName, transitionDefinition);
        context.consume(TokenType.SEMICOLON, "Expected ';' after transition variable declaration");
    }

    /**
     * Sets the variable name for this transition
     */
    public void setVariableName(String variableName) {
        this.variableName = variableName;
    }
}
