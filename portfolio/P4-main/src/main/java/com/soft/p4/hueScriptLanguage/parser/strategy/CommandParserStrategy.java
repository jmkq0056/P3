package com.soft.p4.hueScriptLanguage.parser.strategy;

import com.soft.p4.hueScriptLanguage.parser.ParserContext;
import com.soft.p4.hueScriptLanguage.ast.ScriptNode;

/**
 * Parser strategy for Hue script commands. Each implementation handles a
 * specific command syntax and generates corresponding AST nodes.
 */
public interface CommandParserStrategy {

    /**
     * Parses a command from the current token stream and adds it to the AST.
     * Assumes the command's initial token has already been consumed.
     *
     * @param context Current parser state and helper methods
     * @param scriptNode AST root to add the parsed command to
     * @throws ParserException on syntax errors or invalid values
     */
    void parse(ParserContext context, ScriptNode scriptNode);
}
