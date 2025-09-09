package com.soft.p4.hueScriptLanguage.parser.strategy.all;

import java.util.Map;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.all.SceneCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.parser.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.parser.strategy.group.GroupCommandParserStrategy;
import com.soft.p4.hueScriptLanguage.parser.strategy.single.LightCommandParserStrategy;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Parses scene definitions in the format: define scene <name> { commands... }
 * Supports all command types except nested scene definitions.
 */
public class SceneDefinitionParserStrategy implements CommandParserStrategy {

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();
        Map<String, SceneCommand> scenes = context.getScenes();

        // Validate scene keyword
        if (!context.match(TokenType.SCENE)) {
            throw new ParserException("Expected 'scene' after 'define' at line " + lineNumber);
        }

        // Parse scene name
        if (!context.match(TokenType.IDENTIFIER)) {
            throw new ParserException("Expected scene name at line " + lineNumber);
        }

        String sceneName = context.previous().getValue();

        // Parse scene body
        context.consume(TokenType.LEFT_BRACE, "Expected '{' after scene name");
        ScriptNode tempNode = new ScriptNode();

        // Parse commands until closing brace
        while (!context.isAtEnd() && context.peek().getType() != TokenType.RIGHT_BRACE) {
            try {
                TokenType tokenType = context.peek().getType();

                // Identify which command we're about to parse
                if (tokenType == TokenType.LIGHTS) {
                    context.advance(); // Consume the token
                    if (context.peek().getType() == TokenType.COLOR) {
                        new LightsColorCommandParserStrategy().parse(context, tempNode);
                    } else {
                        new LightsOnOffCommandParserStrategy().parse(context, tempNode);
                    }
                } // Support for individual light commands
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
                    context.advance(); // Consume the token
                    new RepeatCommandParserStrategy().parse(context, tempNode);
                } else if (tokenType == TokenType.TRANSITION) {
                    context.advance(); // Consume the token
                    new TransitionCommandParserStrategy().parse(context, tempNode);
                } else if (tokenType == TokenType.SCENE) {
                    context.advance(); // Consume the token
                    new SceneInvocationParserStrategy().parse(context, tempNode);
                } // Adds support for group commands within scenes
                else if (tokenType == TokenType.GROUP) {
                    context.advance(); // Consume the GROUP token
                    new GroupCommandParserStrategy().parse(context, tempNode);
                } // Support for variable invocations within scenes
                else if (tokenType == TokenType.IDENTIFIER) {
                    context.advance(); // Consume the identifier token
                    new VariableInvocationParserStrategy().parse(context, tempNode);
                } else {
                    throw new ParserException("Unexpected token in scene definition: "
                            + context.peek().getValue() + " at line " + context.peek().getLineNumber());
                }
            } catch (ParserException e) {
                context.skipToSemicolon();
                throw e;
            }
        }

        // Expect closing brace
        context.consume(TokenType.RIGHT_BRACE, "Expected '}' to close scene definition");

        // Create the scene and register it
        SceneCommand scene = new SceneCommand(sceneName, tempNode.getCommands(), lineNumber);
        scenes.put(sceneName, scene);

        System.out.println("Scene registered: " + sceneName + " with "
                + tempNode.getCommands().size() + " commands"); // Debug log
    }
}
