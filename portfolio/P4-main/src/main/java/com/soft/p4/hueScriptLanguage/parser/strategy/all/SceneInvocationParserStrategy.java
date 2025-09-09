package com.soft.p4.hueScriptLanguage.parser.strategy.all;

import java.util.Map;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.all.SceneCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.SceneInvocationCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.parser.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Parses scene invocations in the format: scene <name>; Not allowed inside
 * repeat blocks.
 */
public class SceneInvocationParserStrategy implements CommandParserStrategy {

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();
        Map<String, SceneCommand> scenes = context.getScenes();

        // Validate context
        if (context.isInsideLoop()) {
            throw new ParserException("Scene invocation is not allowed inside repeat blocks at line " + lineNumber);
        }

        // Parse scene name
        if (!context.match(TokenType.IDENTIFIER)) {
            throw new ParserException("Expected scene name at line " + lineNumber);
        }

        String sceneName = context.previous().getValue();

        // Validate scene exists
        if (!scenes.containsKey(sceneName)) {
            throw new ParserException("Undefined scene '" + sceneName + "' at line " + lineNumber);
        }

        scriptNode.addCommand(new SceneInvocationCommand(sceneName, lineNumber));
        context.consume(TokenType.SEMICOLON, "Expected ';' after scene invocation");
    }
}
