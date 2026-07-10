module ppl7.ast.node.NodeRef;

import ppl7.all;

/**
 * NodeRef
 *
 * Used to reference another Node in the AST.
 */
final class NodeRef : Expression {
public:
    Expression node;

    // Node
    override ENode enode() { return ENode.NODE_REF; }
    override bool isResolved() { return node.isResolved(); }

    // Statement
    override Type getType() { return node.getType(); }

    // Expression
    override int precedence() { return node.precedence(); }

    override string toString() {
        return "NodeRef %s".format(node.enode());
    }
}


