package com.soft.p4.hueScriptLanguage.ast.command.all;

import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Represents a brightness control command in the script. Adjusts the brightness
 * level of lights from 0-100%. Can target either all lights or a specific light
 * by ID.
 */
public class BrightnessCommand implements Command {

    private final int level;           // Brightness level (0-100)
    private final int lineNumber;
    private final String lightId;      // Target light identifier, null for all lights
    private final boolean isGlobal;    // True if targeting all lights

    /**
     * Creates a command that affects all lights
     *
     * @param level Brightness level (0-100)
     * @param lineNumber Source line number in script
     */
    public BrightnessCommand(int level, int lineNumber) {
        this.level = level;
        this.lineNumber = lineNumber;
        this.lightId = null;
        this.isGlobal = true;
    }

    /**
     * Creates a command that targets a specific light
     *
     * @param level Brightness level (0-100)
     * @param lightId Identifier of the target light
     * @param lineNumber Source line number in script
     */
    public BrightnessCommand(int level, String lightId, int lineNumber) {
        this.level = level;
        this.lineNumber = lineNumber;
        this.lightId = lightId;
        this.isGlobal = false;
    }

    public int getLevel() {
        return level;
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
