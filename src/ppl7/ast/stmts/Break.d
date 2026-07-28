module ppl7.ast.stmts.Break;

import ppl7.all;

/**
 * Break
 *      [ Expression ]     number of scopes to break out of
 */
final class Break : Statement {
public:
    // Node
    override ENode enode() { return ENode.BREAK; }
    override bool isResolved() { return true; }

    // Statement
    override Type getType() { return STATIC_VOID; }

    Expression numScopesExpr() { return first().as!Expression; }
    int numScopes() { return getConstantNumber(numScopesExpr()).getAsInt(); }

    override string toString() {
        return "Break";
    }
}
