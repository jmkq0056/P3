package com.soft.p4.hueScriptLanguage.ast.command.group;

import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Controls the power state (on/off) of all lights in a group.
 */
public class GroupLightCommand implements Command {

    public enum Action {
        ON, OFF
    }

    private final String groupName; // Target group identifier
    private final Action action;    // Power state to set
    private final int lineNumber;

    public GroupLightCommand(String groupName, Action action, int lineNumber) {
        this.groupName = groupName;
        this.action = action;
        this.lineNumber = lineNumber;
    }

    public String getGroupName() {
        return groupName;
    }

    public Action getAction() {
        return action;
    }

    public int getLineNumber() {
        return lineNumber;
    }

    @Override
    public void accept(NodeVisitor visitor) {
        visitor.visit(this);
    }
}
