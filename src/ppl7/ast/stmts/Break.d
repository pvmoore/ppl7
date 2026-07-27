module ppl7.ast.stmts.Break;

import ppl7.all;

/**
 * Break
 */
final class Break : Statement {
public:
    // Node
    override ENode enode() { return ENode.BREAK; }
    override bool isResolved() { return true; }

    // Statement
    override Type getType() { return STATIC_VOID; }

    override string toString() {
        return "Break";
    }
}
