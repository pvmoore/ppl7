module ppl7.ast.Index;

import ppl7.all;

/**
 * Index
 *     Expression    index
 *     Expression    array | ptr
 */
final class Index : Expression {
public:
    // Node
    override ENode enode() { return ENode.INDEX; }
    override bool isResolved() { return expr().isResolved() && index().isResolved(); }

    // Statement
    override Type getType() {
        Type t = expr().getType();
        if(!t.isResolved()) return t;

        if(auto a = t.extract!Array) {
            return a.elementType();
        }
        if(auto p = t.extract!PointerType) {
            return p.valueExpr().getType();
        }
        return makeUnknownType();
    }

    // Expression
    override int precedence() { return Precedence.INDEX; }

    Expression expr() { return last().as!Expression; }
    Expression index() { return first().as!Expression; }

    bool isArrayIndex() { return expr().getType().extract!Array !is null; }
    bool isPointerIndex() { return expr().getType().extract!PointerType !is null; }

    override string toString() {
        string t = getType().isResolved() ? " %s".format(getType()) : "UNRESOLVED";
        return "[index]%s".format(t);
    }
}
