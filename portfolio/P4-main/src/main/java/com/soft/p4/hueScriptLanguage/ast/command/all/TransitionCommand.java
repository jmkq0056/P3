package com.soft.p4.hueScriptLanguage.ast.command.all;

import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Represents a color transition command in the script. Smoothly transitions
 * between two colors over a specified duration. Can target all lights or a
 * specific light.
 */
public class TransitionCommand implements Command {

    private final String fromColorValue;
    private final String toColorValue;
    private final int duration;
    private final String timeUnit;
    private final int lineNumber;
    private final String lightId; // Target light identifier, null for all lights
    private final boolean isGlobal; // True if targeting all lights

    /**
     * Creates a transition that affects all lights
     */
    public TransitionCommand(String fromColorValue, String toColorValue, int duration, String timeUnit, int lineNumber) {
        this.fromColorValue = fromColorValue;
        this.toColorValue = toColorValue;
        this.duration = duration;
        this.timeUnit = timeUnit;
        this.lineNumber = lineNumber;
        this.lightId = null;
        this.isGlobal = true;
    }

    /**
     * Creates a transition that targets a specific light
     */
    public TransitionCommand(String fromColorValue, String toColorValue, int duration, String timeUnit, String lightId, int lineNumber) {
        this.fromColorValue = fromColorValue;
        this.toColorValue = toColorValue;
        this.duration = duration;
        this.timeUnit = timeUnit;
        this.lineNumber = lineNumber;
        this.lightId = lightId;
        this.isGlobal = false;
    }

    public String getFromColorValue() {
        return fromColorValue;
    }

    public String getToColorValue() {
        return toColorValue;
    }

    public int getDuration() {
        return duration;
    }

    public String getTimeUnit() {
        return timeUnit;
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

    /**
     * Converts the duration to milliseconds based on the specified time unit.
     * Supports ms, sec, min, and hr units.
     */
    public long getDurationInMillis() {
        switch (timeUnit.toLowerCase()) {
            case "ms":
            case "milliseconds":
            case "millisecond":
                return duration;
            case "sec":
            case "seconds":
            case "second":
                return duration * 1000L;
            case "min":
            case "minutes":
            case "minute":
                return duration * 60 * 1000L;
            case "hr":
            case "hours":
            case "hour":
                return duration * 60 * 60 * 1000L;
            default:
                return duration; // Default to ms
        }
    }

    @Override
    public void accept(NodeVisitor visitor) {
        visitor.visit(this);
    }
}
