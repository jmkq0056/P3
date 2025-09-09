package com.soft.p4.hueScriptLanguage.ast.command.all;

import com.soft.p4.hueScriptLanguage.ast.NodeVisitor;
import com.soft.p4.hueScriptLanguage.ast.command.Command;

/**
 * Represents a scene invocation in the script. Executes a previously defined
 * scene by its name, allowing reuse of command sequences. Acts as a function
 * call in the script language.
 */
public class SceneInvocationCommand implements Command {

    private final String sceneName;    // Name of the scene to execute
    private final int lineNumber;

    /**
     * Creates a new scene invocation command
     *
     * @param sceneName Name of the scene to execute
     * @param lineNumber Source line number in script
     */
    public SceneInvocationCommand(String sceneName, int lineNumber) {
        this.sceneName = sceneName;
        this.lineNumber = lineNumber;
    }

    public String getSceneName() {
        return sceneName;
    }

    public int getLineNumber() {
        return lineNumber;
    }

    @Override
    public void accept(NodeVisitor visitor) {
        visitor.visit(this);
    }
}
