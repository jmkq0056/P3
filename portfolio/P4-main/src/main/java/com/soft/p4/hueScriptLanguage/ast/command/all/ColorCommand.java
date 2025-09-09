package com.soft.p4.hueScriptLanguage.ast.command.all;

import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Represents a color change command in the script. Sets the color of lights
 * using hex color values (e.g. #FF0000). Can target either all lights or a
 * specific light by ID.
 */
public class ColorCommand implements Command {

    private final String colorValue;    // Hex color value (e.g. #FF0000)
    private final int lineNumber;
    private final String lightId;       // Target light identifier, null for all lights
    private final boolean isGlobal;     // True if targeting all lights

    /**
     * Creates a command that affects all lights
     *
     * @param colorValue Hex color value (e.g. #FF0000)
     * @param lineNumber Source line number in script
     */
    public ColorCommand(String colorValue, int lineNumber) {
        this.colorValue = colorValue;
        this.lineNumber = lineNumber;
        this.lightId = null;
        this.isGlobal = true;
    }

    /**
     * Creates a command that targets a specific light
     *
     * @param colorValue Hex color value (e.g. #FF0000)
     * @param lightId Identifier of the target light
     * @param lineNumber Source line number in script
     */
    public ColorCommand(String colorValue, String lightId, int lineNumber) {
        this.colorValue = colorValue;
        this.lineNumber = lineNumber;
        this.lightId = lightId;
        this.isGlobal = false;
    }

    public String getColorValue() {
        return colorValue;
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
