package com.soft.p4.hueScriptLanguage.ast.command.all;

import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Represents a light power state command in the script. Can target either all
 * lights or a specific light by ID.
 */
public class LightCommand implements Command {

    public enum Action {
        ON, OFF
    }

    private final Action action;
    private final int lineNumber;
    private final String lightId;      // Target light identifier, null for all lights
    private final boolean isGlobal;    // True if targeting all lights

    /**
     * Creates a command that affects all lights
     */
    public LightCommand(Action action, int lineNumber) {
        this.action = action;
        this.lineNumber = lineNumber;
        this.lightId = null;
        this.isGlobal = true;
    }

    /**
     * Creates a command that targets a specific light
     */
    public LightCommand(Action action, String lightId, int lineNumber) {
        this.action = action;
        this.lineNumber = lineNumber;
        this.lightId = lightId;
        this.isGlobal = false;
    }

    public Action getAction() {
        return action;
    }

    public int getLineNumber() {
        return lineNumber;
    }

    public String getLightId() {
        return lightId;
    }

    public boolean isGlobal() {
        return isGlobal;
    }

    @Override
    public void accept(NodeVisitor visitor) {
        visitor.visit(this);
    }
}
