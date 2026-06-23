module ppl7.ast.Identifier;

import ppl7.all;

/**
 * Identifier
 */
final class Identifier : Expression {
public:
    string name;
    TargetOfIdentifier target;

    // Node
    override ENode enode() { return ENode.IDENTIFIER; }
    override bool isResolved() { return resolveEvaluated && target.isResolved(); }

    // Statement
    override Type getType() { return target.getType(); }

    // Expression
    override int precedence() { return Precedence.LOWEST; }
    
    override string toString() {
        return "%s %s".format(name, target);
    }
}

Identifier makeIdentifier(Module mod, string name) {
    auto i = makeNode!Identifier(0);
    i.target.identifier = i;
    i.name = name;
    return i;
}
