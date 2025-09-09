package com.soft.p4.hueScriptLanguage.ast.command.all;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Represents a loop construct in the script. Supports both count-based and
 * time-based repetition of commands.
 */
public class RepeatCommand implements Command {

    private final int times;           // Number of iterations for count-based loops
    private final List<Command> commands;
    private final int lineNumber;
    private final long duration;       // Duration in ms for time-based loops
    private final boolean isTimeBased; // True for time-based, false for count-based
    private final String timeUnit;     // Original time unit for error messages

    /**
     * Creates a count-based loop that repeats a fixed number of times
     */
    public RepeatCommand(int times, List<Command> commands, int lineNumber) {
        this.times = times;
        this.commands = new ArrayList<>(commands);
        this.lineNumber = lineNumber;
        this.duration = 0;
        this.isTimeBased = false;
        this.timeUnit = "";
    }

    /**
     * Creates a time-based loop that repeats for a specified duration. Supports
     * ms, sec, min, and hr units.
     */
    public RepeatCommand(int duration, String timeUnit, List<Command> commands, int lineNumber) {
        this.times = 0;
        this.commands = new ArrayList<>(commands);
        this.lineNumber = lineNumber;
        this.timeUnit = timeUnit;
        this.isTimeBased = true;

        // Normalize duration to milliseconds
        switch (timeUnit.toLowerCase()) {
            case "ms":
            case "milliseconds":
            case "millisecond":
                this.duration = duration;
                break;
            case "sec":
            case "seconds":
            case "second":
                this.duration = duration * 1000L;
                break;
            case "min":
            case "minutes":
            case "minute":
                this.duration = duration * 60 * 1000L;
                break;
            case "hr":
            case "hours":
            case "hour":
                this.duration = duration * 60 * 60 * 1000L;
                break;
            default:
                this.duration = duration; // Default to ms
        }
    }

    public int getTimes() {
        return times;
    }

    public long getDuration() {
        return duration;
    }

    public boolean isTimeBased() {
        return isTimeBased;
    }

    public String getTimeUnit() {
        return timeUnit;
    }

    public List<Command> getCommands() {
        return Collections.unmodifiableList(commands);
    }

    public int getLineNumber() {
        return lineNumber;
    }

    @Override
    public void accept(NodeVisitor visitor) {
        visitor.visit(this);
    }
}
