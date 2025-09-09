package com.soft.p4.hueScriptLanguage.strategy.all;

import java.util.ArrayList;
import java.util.List;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.Command;
import com.soft.p4.hueScriptLanguage.ast.command.all.RepeatCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.strategy.group.GroupCommandParserStrategy;
import com.soft.p4.hueScriptLanguage.strategy.single.LightCommandParserStrategy;
import com.soft.p4.hueScriptLanguage.lexer.Token;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Parses repeat blocks in two formats: 1. Count-based: repeat [for] <count>
 * times { commands... } 2. Time-based: repeat [for] <duration> <unit> {
 * commands... }
 *
 * Time units: ms, sec, min, hr Validates nested loops and transition durations
 * in time-based loops.
 */
public class RepeatCommandParserStrategy implements CommandParserStrategy {

    @Override
    public void parse(ParserContext context, ScriptNode parentNode) {
        int lineNumber = context.previous().getLineNumber();

        // Track loop nesting state
        boolean wasInsideLoop = context.isInsideLoop();
        context.setInsideLoop(true);

        // Optional "for" keyword
        boolean hasForKeyword = false;
        if (context.match(TokenType.FOR)) {
            hasForKeyword = true;
        }

        // Parse iteration count or duration
        if (!context.match(TokenType.NUMBER)) {
            throw new ParserException("Expected number after 'repeat" + (hasForKeyword ? " for" : "") + "' at line " + lineNumber);
        }

        int value;
        try {
            value = Integer.parseInt(context.previous().getValue());
            if (value <= 0) {
                throw new ParserException("Repeat value must be positive at line " + lineNumber);
            }
        } catch (NumberFormatException e) {
            throw new ParserException("Invalid repeat value at line " + lineNumber);
        }

        // Check if it's a time-based repetition (for X seconds/minutes/hours)
        boolean isTimeBased = false;
        String timeUnit = "";
        long loopDurationMs = 0; // Duration of time-based loop in milliseconds

        if (context.peek().getType() == TokenType.SEC
                || context.peek().getType() == TokenType.SECONDS
                || context.peek().getType() == TokenType.SECOND
                || context.peek().getType() == TokenType.MIN
                || context.peek().getType() == TokenType.MINUTES
                || context.peek().getType() == TokenType.MINUTE
                || context.peek().getType() == TokenType.HR
                || context.peek().getType() == TokenType.HOURS
                || context.peek().getType() == TokenType.HOUR
                || context.peek().getType() == TokenType.MS
                || context.peek().getType() == TokenType.MILLISECONDS
                || context.peek().getType() == TokenType.MILLISECOND) {

            isTimeBased = true;
            timeUnit = context.peek().getValue();
            context.advance(); // Consume the time unit token

            // Calculate loop duration in milliseconds for validation
            switch (timeUnit.toLowerCase()) {
                case "ms":
                case "milliseconds":
                case "millisecond":
                    loopDurationMs = value;
                    break;
                case "sec":
                case "seconds":
                case "second":
                    loopDurationMs = value * 1000L;
                    break;
                case "min":
                case "minutes":
                case "minute":
                    loopDurationMs = value * 60 * 1000L;
                    break;
                case "hr":
                case "hours":
                case "hour":
                    loopDurationMs = value * 60 * 60 * 1000L;
                    break;
                default:
                    loopDurationMs = value; // Default to milliseconds
            }
        } // Check for the 'times' keyword (count-based repetition)
        else if (context.peek().getType() == TokenType.TIMES) {
            isTimeBased = false;
            context.advance(); // Consume 'times' token
        } // Allow the number by itself for count-based repetition
        else if (context.peek().getType() == TokenType.LEFT_BRACE) {
            // If we immediately see a left brace, assume this is count-based with no "times" keyword
            isTimeBased = false;
        } else {
            throw new ParserException("Expected 'times' or time unit (sec/min/hr/ms) after repeat count at line " + lineNumber);
        }

        // Expect opening brace
        context.consume(TokenType.LEFT_BRACE, "Expected '{' after repeat parameters");

        // Parse the nested commands
        List<Command> commands = new ArrayList<>();

        // Track if we're inside a time-based repeat for nested loop validation
        boolean insideTimeBased = isTimeBased;

        // For validating transition durations inside time-based loops
        List<Long> transitionDurations = new ArrayList<>();

        // Parse commands until closing brace
        while (!context.isAtEnd() && context.peek().getType() != TokenType.RIGHT_BRACE) {
            // Create a temporary script node to collect commands
            ScriptNode tempNode = new ScriptNode();

            // Parse a single statement (this will add the command to tempNode)
            TokenType tokenType = context.peek().getType();

            if (tokenType == TokenType.LIGHTS) {
                context.advance(); // Consume the token

                // Delegate to the appropriate strategy
                if (context.peek().getType() == TokenType.COLOR) {
                    new LightsColorCommandParserStrategy().parse(context, tempNode);
                } else {
                    new LightsOnOffCommandParserStrategy().parse(context, tempNode);
                }
            } // Adds support for individual light commands
            else if (tokenType == TokenType.LIGHT) {
                context.advance(); // Consume the token
                new LightCommandParserStrategy().parse(context, tempNode);
            } else if (tokenType == TokenType.BRIGHTNESS) {
                context.advance(); // Consume the token
                new BrightnessCommandParserStrategy().parse(context, tempNode);
            } else if (tokenType == TokenType.WAIT) {
                context.advance(); // Consume the token
                new WaitCommandParserStrategy().parse(context, tempNode);
            } else if (tokenType == TokenType.REPEAT) {
                // If this is a nested loop inside a time-based loop, enforce that it must be count-based
                Token peekAhead = context.getTokens().get(context.getTokens().indexOf(context.peek()) + 1);

                // Handle the case where "for" might be present
                if (context.peek().getType() == TokenType.FOR) {
                    peekAhead = context.getTokens().get(context.getTokens().indexOf(context.peek()) + 2);
                }

                if (peekAhead.getType() == TokenType.NUMBER) {
                    // Look ahead further to see if it's followed by a time unit
                    Token afterNumber = context.getTokens().get(
                            context.getTokens().indexOf(context.peek()) + (context.peek().getType() == TokenType.FOR ? 3 : 2)
                    );

                    boolean innerIsTimeBased = (afterNumber.getType() == TokenType.SEC
                            || afterNumber.getType() == TokenType.MIN
                            || afterNumber.getType() == TokenType.HR
                            || afterNumber.getType() == TokenType.SECONDS
                            || afterNumber.getType() == TokenType.MINUTES
                            || afterNumber.getType() == TokenType.HOURS
                            || afterNumber.getType() == TokenType.MS
                            || afterNumber.getType() == TokenType.MILLISECONDS
                            || afterNumber.getType() == TokenType.MILLISECOND
                            || afterNumber.getType() == TokenType.SECOND
                            || afterNumber.getType() == TokenType.MINUTE
                            || afterNumber.getType() == TokenType.HOUR);

                    // If outer loop is time-based and inner loop is also time-based, throw error
                    if (insideTimeBased && innerIsTimeBased) {
                        throw new ParserException("Nested time-based repeats are not allowed. Inner repeat must use 'times' at line "
                                + peekAhead.getLineNumber());
                    }
                }

                context.advance(); // Consume the token
                new RepeatCommandParserStrategy().parse(context, tempNode);
            } else if (tokenType == TokenType.TRANSITION) {
                // For time-based loops, we need to validate the transition durations
                if (insideTimeBased) {
                    validateTransitionInTimedLoop(context, lineNumber, loopDurationMs);
                }

                context.advance(); // Consume the token
                new TransitionCommandParserStrategy().parse(context, tempNode);
            } else if (tokenType == TokenType.SCENE) {
                // Not allowing scene invocation inside a repeat block
                throw new ParserException("Scene invocation is not allowed inside repeat blocks at line "
                        + context.peek().getLineNumber());
            } // Add support for group commands within repeat blocks
            else if (tokenType == TokenType.GROUP) {
                context.advance(); // Consume the GROUP token
                new GroupCommandParserStrategy().parse(context, tempNode);
            } // Add support for variable invocations within repeat blocks
            else if (tokenType == TokenType.IDENTIFIER) {
                context.advance(); // Consume the identifier token
                new VariableInvocationParserStrategy().parse(context, tempNode);
            } else {
                throw new ParserException("Unexpected token in repeat block: " + context.peek().getValue()
                        + " at line " + context.peek().getLineNumber());
            }

            // Add commands from the temp node to our command list
            commands.addAll(tempNode.getCommands());
        }

        // Expect closing brace
        context.consume(TokenType.RIGHT_BRACE, "Expected '}' to close repeat block");

        // Reset the insideLoop flag to its previous state when exiting this loop
        context.setInsideLoop(wasInsideLoop);

        // Create the RepeatCommand and add it to the parent node
        if (isTimeBased) {
            parentNode.addCommand(new RepeatCommand(value, timeUnit, commands, lineNumber));
        } else {
            parentNode.addCommand(new RepeatCommand(value, commands, lineNumber));
        }
    }

    /**
     * Validates transition duration against loop duration to prevent infinite
     * loops
     */
    private void validateTransitionInTimedLoop(ParserContext context, int lineNumber, long loopDurationMs) {
        // Save the position to restore it after lookahead
        int savedPosition = context.getTokens().indexOf(context.peek());

        try {
            // Skip transition token - already consumed

            // Skip from color
            context.match(TokenType.STRING);

            // Skip "to" keyword
            context.match(TokenType.TO);

            // Skip to color
            context.match(TokenType.STRING);

            // Look for transition duration info
            // Skip "over" or "in"
            if (context.peek().getValue().equalsIgnoreCase("over")
                    || context.peek().getValue().equalsIgnoreCase("in")) {
                context.advance();
            }

            // Get duration value
            if (context.match(TokenType.NUMBER)) {
                int durationValue = Integer.parseInt(context.previous().getValue());

                // Get time unit
                if (context.peek().getType() == TokenType.SEC
                        || context.peek().getType() == TokenType.SECONDS
                        || context.peek().getType() == TokenType.SECOND
                        || context.peek().getType() == TokenType.MIN
                        || context.peek().getType() == TokenType.MINUTES
                        || context.peek().getType() == TokenType.MINUTE
                        || context.peek().getType() == TokenType.HR
                        || context.peek().getType() == TokenType.HOURS
                        || context.peek().getType() == TokenType.HOUR
                        || context.peek().getType() == TokenType.MS
                        || context.peek().getType() == TokenType.MILLISECONDS
                        || context.peek().getType() == TokenType.MILLISECOND) {

                    String durTimeUnit = context.peek().getValue();

                    // Calculate transition duration in milliseconds
                    long transitionDurationMs = 0;
                    switch (durTimeUnit.toLowerCase()) {
                        case "ms":
                        case "milliseconds":
                        case "millisecond":
                            transitionDurationMs = durationValue;
                            break;
                        case "sec":
                        case "seconds":
                        case "second":
                            transitionDurationMs = durationValue * 1000L;
                            break;
                        case "min":
                        case "minutes":
                        case "minute":
                            transitionDurationMs = durationValue * 60 * 1000L;
                            break;
                        case "hr":
                        case "hours":
                        case "hour":
                            transitionDurationMs = durationValue * 60 * 60 * 1000L;
                            break;
                        default:
                            transitionDurationMs = durationValue;
                    }

                    // Validate the transition won't exceed loop duration
                    if (transitionDurationMs > loopDurationMs) {
                        throw new ParserException("Transition duration (" + durationValue + " "
                                + durTimeUnit + ") exceeds the time-based loop duration at line " + lineNumber);
                    }
                }
            }
        } catch (ParserException e) {
            // Re-throw parser exceptions
            throw e;
        } catch (Exception e) {
            // For any other exception, just continue - we're just validating
        } finally {
            // Restore position to parse normally
            // Because we can't directly set the current token index,
            // we'll advance the token pointer to just before the saved position
            while (context.getTokens().indexOf(context.peek()) < savedPosition) {
                context.advance();
            }
        }
    }
}
