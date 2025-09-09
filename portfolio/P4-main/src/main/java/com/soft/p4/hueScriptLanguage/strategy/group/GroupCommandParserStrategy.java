package com.soft.p4.hueScriptLanguage.strategy.group;

import java.util.ArrayList;
import java.util.List;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupBrightnessCommand;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupColorCommand;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupDefineCommand;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupLightCommand;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupTransitionCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Handles group-related commands in two formats: 1. Definition: group "<name>"
 * = "<light1, light2, ...>"; 2. Operations: group "<name>" (on|off|brightness
 * <level>|color <value>|transition ...);
 */
public class GroupCommandParserStrategy implements CommandParserStrategy {

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();

        // Parse group name
        if (!context.match(TokenType.STRING)) {
            throw new ParserException("Expected group name as string at line " + lineNumber);
        }

        String groupName = context.previous().getValue();
        groupName = groupName.substring(1, groupName.length() - 1);

        // Route to appropriate parser based on next token
        if (context.match(TokenType.ASSIGN)) {
            parseGroupDefinition(context, scriptNode, groupName, lineNumber);
        } else {
            parseGroupOperation(context, scriptNode, groupName, lineNumber);
        }
    }

    /**
     * Parses group definitions, validating light IDs and ensuring non-empty
     * groups
     */
    private void parseGroupDefinition(ParserContext context, ScriptNode scriptNode,
            String groupName, int lineNumber) {
        if (!context.match(TokenType.STRING)) {
            throw new ParserException("Expected comma-separated light IDs as string at line " + lineNumber);
        }

        String lightIdsString = context.previous().getValue();
        lightIdsString = lightIdsString.substring(1, lightIdsString.length() - 1);

        // Extract and validate light IDs
        List<String> lightIds = new ArrayList<>();
        String[] parts = lightIdsString.split(",");
        for (String part : parts) {
            String lightId = part.trim();
            if (!lightId.isEmpty()) {
                lightIds.add(lightId);
            }
        }

        if (lightIds.isEmpty()) {
            throw new ParserException("Group must contain at least one light ID at line " + lineNumber);
        }

        context.consume(TokenType.SEMICOLON, "Expected ';' after group definition");
        scriptNode.addCommand(new GroupDefineCommand(groupName, lightIds, lineNumber));
    }

    /**
     * Parses group operations: power, brightness, color, and transitions
     */
    private void parseGroupOperation(ParserContext context, ScriptNode scriptNode,
            String groupName, int lineNumber) {
        TokenType operationType = context.peek().getType();

        // Handle power state changes
        if (operationType == TokenType.ON) {
            context.advance();
            context.consume(TokenType.SEMICOLON, "Expected ';' after 'group " + groupName + " on'");
            scriptNode.addCommand(new GroupLightCommand(groupName, GroupLightCommand.Action.ON, lineNumber));
        } else if (operationType == TokenType.OFF) {
            context.advance();
            context.consume(TokenType.SEMICOLON, "Expected ';' after 'group " + groupName + " off'");
            scriptNode.addCommand(new GroupLightCommand(groupName, GroupLightCommand.Action.OFF, lineNumber));
        } // Handle brightness adjustment
        else if (operationType == TokenType.BRIGHTNESS) {
            context.advance();

            if (!context.match(TokenType.NUMBER)) {
                throw new ParserException("Expected brightness level (0-100) at line " + lineNumber);
            }

            int level;
            try {
                level = Integer.parseInt(context.previous().getValue());
                if (level < 0 || level > 100) {
                    throw new ParserException("Brightness level must be between 0 and 100 at line " + lineNumber);
                }
            } catch (NumberFormatException e) {
                throw new ParserException("Invalid number format for brightness at line " + lineNumber);
            }

            context.consume(TokenType.SEMICOLON, "Expected ';' after brightness level");
            scriptNode.addCommand(new GroupBrightnessCommand(groupName, level, lineNumber));
        } // Handle color changes
        else if (operationType == TokenType.COLOR) {
            context.advance();

            String colorValue;
            if (context.match(TokenType.STRING)) {
                colorValue = context.previous().getValue();
                colorValue = colorValue.substring(1, colorValue.length() - 1);
                colorValue = context.validateAndResolveColor(colorValue, lineNumber);
            } else if (context.match(TokenType.IDENTIFIER)) {
                String variableName = context.previous().getValue();
                if (!context.getVariables().containsKey(variableName)) {
                    throw new ParserException("Undefined variable '" + variableName + "' at line " + lineNumber);
                }
                colorValue = context.getVariables().get(variableName);
            } else {
                throw new ParserException("Expected color value (as string or variable) at line " + lineNumber);
            }

            context.consume(TokenType.SEMICOLON, "Expected ';' after color value");
            scriptNode.addCommand(new GroupColorCommand(groupName, colorValue, lineNumber));
        } // Handle color transitions
        else if (operationType == TokenType.TRANSITION) {
            context.advance();

            // Parse source color
            String fromColorValue;
            String resolvedFromColor;

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
                throw new ParserException("Expected color value after 'transition' at line " + lineNumber);
            }

            context.consume(TokenType.TO, "Expected 'to' after from-color in transition command");

            // Parse target color
            String toColorValue;
            String resolvedToColor;

            if (context.match(TokenType.STRING)) {
                toColorValue = context.previous().getValue();
                toColorValue = toColorValue.substring(1, toColorValue.length() - 1);
                resolvedToColor = context.validateAndResolveColor(toColorValue, lineNumber);
            } else if (context.match(TokenType.IDENTIFIER)) {
                String variableName = context.previous().getValue();
                if (!context.getVariables().containsKey(variableName)) {
                    throw new ParserException("Undefined variable '" + variableName + "' at line " + lineNumber);
                }
                resolvedToColor = context.getVariables().get(variableName);
            } else {
                throw new ParserException("Expected color value after 'to' at line " + lineNumber);
            }

            // Parse transition timing
            if (!(context.peek().getValue().equalsIgnoreCase("over")
                    || context.peek().getValue().equalsIgnoreCase("in"))) {
                throw new ParserException("Expected 'over' or 'in' after to-color in transition command at line " + lineNumber);
            }
            context.advance();

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

            // Parse time unit
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

            context.consume(TokenType.SEMICOLON, "Expected ';' after transition command");
            scriptNode.addCommand(new GroupTransitionCommand(groupName, resolvedFromColor, resolvedToColor,
                    duration, timeUnit, lineNumber));
        } else {
            throw new ParserException("Expected group operation (on/off/brightness/color/transition) at line " + lineNumber);
        }
    }
}
