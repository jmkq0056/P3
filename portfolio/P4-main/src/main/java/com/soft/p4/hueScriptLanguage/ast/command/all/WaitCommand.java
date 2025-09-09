package com.soft.p4.hueScriptLanguage.ast.command.all;

import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Represents a pause in script execution. Supports various time units for
 * duration specification.
 */
public class WaitCommand implements Command {

    private final int duration;    // Duration value in specified unit
    private final String timeUnit; // Time unit (ms, sec, min, hr)
    private final int lineNumber;

    /**
     * Creates a wait command with the specified duration
     */
    public WaitCommand(int duration, String timeUnit, int lineNumber) {
        this.duration = duration;
        this.timeUnit = timeUnit;
        this.lineNumber = lineNumber;
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
