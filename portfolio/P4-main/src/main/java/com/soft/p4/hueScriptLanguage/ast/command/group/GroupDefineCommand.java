package com.soft.p4.hueScriptLanguage.ast.command.group;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Creates a named group of lights that can be controlled together.
 */
public class GroupDefineCommand implements Command {

    private final String name;          // Group identifier
    private final List<String> lightIds; // IDs of lights in the group
    private final int lineNumber;

    public GroupDefineCommand(String name, List<String> lightIds, int lineNumber) {
        this.name = name;
        this.lightIds = new ArrayList<>(lightIds);
        this.lineNumber = lineNumber;
    }

    public String getName() {
        return name;
    }

    public List<String> getLightIds() {
        return Collections.unmodifiableList(lightIds);
    }

    public int getLineNumber() {
        return lineNumber;
    }

    @Override
    public void accept(NodeVisitor visitor) {
        visitor.visit(this);
    }
}
