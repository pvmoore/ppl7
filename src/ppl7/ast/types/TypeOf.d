module ppl7.ast.types.TypeOf;

import ppl7.all;

/**
 * TypeOf
 *     Expression
 */
final class TypeOf : Type {
public:
    // Node
    override ENode enode() { return ENode.TYPE_OF; }
    override bool isResolved() { return false; }

    // Type
    override EType etype() { return EType.UNKNOWN; }

    override bool exactlyMatches(Type other) {
        return exactlyMatches(expr().getType());
    }
    override bool canImplicitlyCastTo(Type other) {
        return canImplicitlyCastTo(expr().getType());
    }

    override string shortName() { return "::typeOf(%s)".format(expr()); }
    override string mangledName() { assert(false); }

    Expression expr() { return first().as!Expression; }

    override string toString() {
        return "TypeOf %s".format(expr().enode());
    }
}
