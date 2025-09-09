package com.soft.p4.hueScriptLanguage.ast.command.group;

import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Transitions all lights in a group between two colors over a specified
 * duration. Supports various time units for the transition period.
 */
public class GroupTransitionCommand implements Command {

    private final String groupName;      // Target group identifier
    private final String fromColorValue; // Starting hex color
    private final String toColorValue;   // Target hex color
    private final int duration;          // Duration value in specified unit
    private final String timeUnit;       // Time unit (ms, sec, min, hr)
    private final int lineNumber;

    public GroupTransitionCommand(String groupName, String fromColorValue, String toColorValue,
            int duration, String timeUnit, int lineNumber) {
        this.groupName = groupName;
        this.fromColorValue = fromColorValue;
        this.toColorValue = toColorValue;
        this.duration = duration;
        this.timeUnit = timeUnit;
        this.lineNumber = lineNumber;
    }

    public String getGroupName() {
        return groupName;
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

    /**
     * Converts duration to milliseconds based on the specified time unit
     *
     * @return Duration in milliseconds
     */
    public long getDurationInMillis() {
        switch (timeUnit.toLowerCase()) {
            case "ms":
            case "milliseconds":
            case "millisecond":
                return duration; // Already in milliseconds
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
                return duration;
        }
    }

    @Override
    public void accept(NodeVisitor visitor) {
        visitor.visit(this);
    }
}
