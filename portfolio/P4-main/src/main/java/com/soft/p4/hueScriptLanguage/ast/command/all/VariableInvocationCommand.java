package com.soft.p4.hueScriptLanguage.ast.command.all;

import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Represents a variable invocation in the script. Executes the command sequence
 * stored in a variable, allowing dynamic command execution based on variable
 * content. Supports the script's variable system for command reuse.
 */
public class VariableInvocationCommand implements Command {

    private final String variableName;    // Name of the variable to execute
    private final int lineNumber;

    /**
     * Creates a new variable invocation command
     *
     * @param variableName Name of the variable containing commands to execute
     * @param lineNumber Source line number in script
     */
    public VariableInvocationCommand(String variableName, int lineNumber) {
        this.variableName = variableName;
        this.lineNumber = lineNumber;
    }

    public String getVariableName() {
        return variableName;
    }

    public int getLineNumber() {
        return lineNumber;
    }

    @Override
    public void accept(NodeVisitor visitor) {
        visitor.visit(this);
    }
}
