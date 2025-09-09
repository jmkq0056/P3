package com.soft.p4.hueScriptLanguage.ast.command.group;

import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Sets the brightness level of all lights in a group (0-100%).
 */
public class GroupBrightnessCommand implements Command {

    private final String groupName;  // Target group identifier
    private final int level;        // Brightness level (0-100)
    private final int lineNumber;

    public GroupBrightnessCommand(String groupName, int level, int lineNumber) {
        this.groupName = groupName;
        this.level = level;
        this.lineNumber = lineNumber;
    }

    public String getGroupName() {
        return groupName;
    }

    public int getLevel() {
        return level;
    }

    public int getLineNumber() {
        return lineNumber;
    }

    @Override
    public void accept(NodeVisitor visitor) {
        visitor.visit(this);
    }
}
