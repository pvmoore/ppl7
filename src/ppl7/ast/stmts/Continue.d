module ppl7.ast.stmts.Continue;

import ppl7.all;

/**
 * Continue
 */
final class Continue : Statement {
public:
    // Node
    override ENode enode() { return ENode.CONTINUE; }
    override bool isResolved() { return true; }

    // Statement
    override Type getType() { return STATIC_VOID; }

    override string toString() {
        return "Continue";
    }
}
