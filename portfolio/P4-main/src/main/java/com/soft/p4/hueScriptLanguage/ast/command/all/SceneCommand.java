package com.soft.p4.hueScriptLanguage.ast.command.all;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Represents a named sequence of commands that can be reused. Acts as a
 * reusable function in the script language.
 */
public class SceneCommand implements Command {

    private final String name;          // Scene identifier
    private final List<Command> commands;
    private final int lineNumber;

    /**
     * Creates a new scene with the given name and command sequence
     */
    public SceneCommand(String name, List<Command> commands, int lineNumber) {
        this.name = name;
        this.commands = new ArrayList<>(commands);
        this.lineNumber = lineNumber;
    }

    public String getName() {
        return name;
    }

    /**
     * Returns an unmodifiable view of the scene's commands
     */
    public List<Command> getCommands() {
        return Collections.unmodifiableList(commands);
    }

    public int getLineNumber() {
        return lineNumber;
    }

    @Override
    public void accept(NodeVisitor visitor) {
        visitor.visit(this);
    }
}
