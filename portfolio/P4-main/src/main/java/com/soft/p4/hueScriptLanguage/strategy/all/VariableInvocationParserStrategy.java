package com.soft.p4.hueScriptLanguage.strategy.all;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;
import com.soft.p4.hueScriptLanguage.ast.command.all.VariableInvocationCommand;
import com.soft.p4.hueScriptLanguage.exception.ParserException;
import com.soft.p4.hueScriptLanguage.strategy.CommandParserStrategy;
import com.soft.p4.hueScriptLanguage.lexer.TokenType;

/**
 * Parses direct variable invocations in the format: <variable_name>; Variables
 * must be previously defined and contain either a color or transition.
 */
public class VariableInvocationParserStrategy implements CommandParserStrategy {

    @Override
    public void parse(ParserContext context, ScriptNode scriptNode) {
        int lineNumber = context.previous().getLineNumber();
        String variableName = context.previous().getValue();

        if (!context.getVariables().containsKey(variableName)) {
            throw new ParserException("Undefined variable '" + variableName + "' at line " + lineNumber);
        }

        scriptNode.addCommand(new VariableInvocationCommand(variableName, lineNumber));
        context.consume(TokenType.SEMICOLON, "Expected ';' after variable invocation");
    }
}
