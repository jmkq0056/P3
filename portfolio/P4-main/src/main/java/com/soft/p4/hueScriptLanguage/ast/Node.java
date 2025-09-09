package com.soft.p4.hueScriptLanguage.ast;

/**
 * Base interface for AST nodes. Implements the visitor pattern to enable
 * flexible tree traversal and command execution. All nodes in the syntax tree
 * must implement this interface.
 */
public interface Node {

    /**
     * Accepts a visitor for AST traversal. Delegates to the appropriate visit
     * method based on the concrete node type.
     *
     * @param visitor The visitor implementation to accept
     */
    void accept(NodeVisitor visitor);
}
