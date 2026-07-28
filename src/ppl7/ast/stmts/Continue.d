module ppl7.ast.stmts.Continue;

import ppl7.all;

/**
 * Continue
 *      [ Expression ]     number of scopes to continue out of
 */
final class Continue : Statement {
public:
    // Node
    override ENode enode() { return ENode.CONTINUE; }
    override bool isResolved() { return true; }

    // Statement
    override Type getType() { return STATIC_VOID; }

    Expression numScopesExpr() { return first().as!Expression; }
    int numScopes() { return getConstantNumber(numScopesExpr()).getAsInt(); }

    override string toString() {
        return "Continue";
    }
}
