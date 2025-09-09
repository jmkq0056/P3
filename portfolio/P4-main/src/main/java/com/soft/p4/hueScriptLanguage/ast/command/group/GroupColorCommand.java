package com.soft.p4.hueScriptLanguage.ast.command.group;

import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Sets the color of all lights in a group to a specified hex color value.
 */
public class GroupColorCommand implements Command {

    private final String groupName;  // Target group identifier
    private final String colorValue; // Hex color value (e.g. #FF0000)
    private final int lineNumber;

    public GroupColorCommand(String groupName, String colorValue, int lineNumber) {
        this.groupName = groupName;
        this.colorValue = colorValue;
        this.lineNumber = lineNumber;
    }

    public String getGroupName() {
        return groupName;
    }

    public String getColorValue() {
        return colorValue;
    }

    public int getLineNumber() {
        return lineNumber;
    }

    @Override
    public void accept(NodeVisitor visitor) {
        visitor.visit(this);
    }
}
