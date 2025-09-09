package com.soft.p4.hueScriptLanguage.ast;

import com.soft.p4.hueScriptLanguage.ast.command.all.BrightnessCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.ColorCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.LightCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.RepeatCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.SceneCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.SceneInvocationCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.TransitionCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.VariableInvocationCommand;
import com.soft.p4.hueScriptLanguage.ast.command.all.WaitCommand;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupBrightnessCommand;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupColorCommand;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupDefineCommand;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupLightCommand;
import com.soft.p4.hueScriptLanguage.ast.command.group.GroupTransitionCommand;

/**
 * Visitor interface for AST traversal and command execution. Defines visit
 * methods for each node type in the syntax tree. Implementations handle the
 * actual command execution logic.
 */
public interface NodeVisitor {

    // Script structure
    void visit(ScriptNode node);

    void visit(SceneCommand sceneCommand);

    void visit(SceneInvocationCommand sceneInvocationCommand);

    void visit(VariableInvocationCommand variableInvocationCommand);

    // Single light operations
    void visit(LightCommand node);

    void visit(BrightnessCommand node);

    void visit(ColorCommand node);

    void visit(TransitionCommand node);

    // Flow control
    void visit(WaitCommand node);

    void visit(RepeatCommand node);

    // Group operations
    void visit(GroupDefineCommand groupDefineCommand);

    void visit(GroupLightCommand groupLightCommand);

    void visit(GroupBrightnessCommand groupBrightnessCommand);

    void visit(GroupColorCommand groupColorCommand);

    void visit(GroupTransitionCommand groupTransitionCommand);
}
