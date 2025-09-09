// ScriptNode.java
package com.soft.p4.hueScriptLanguage.ast;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Root node of the AST representing a Hue script. Maintains an ordered sequence
 * of commands for execution.
 */
public class ScriptNode implements Node {

    private final List<Command> commands = new ArrayList<>();

    /**
     * Adds a command to the execution sequence
     */
    public void addCommand(Command command) {
        commands.add(command);
    }

    /**
     * Returns an immutable view of the command sequence
     */
    public List<Command> getCommands() {
        return Collections.unmodifiableList(commands);
    }

    @Override
    public void accept(NodeVisitor visitor) {
        visitor.visit(this);
    }
}
