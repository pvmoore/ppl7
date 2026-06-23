module ppl7.ast.module_.ModuleRef;

import ppl7.all;

/**
 * ModuleRef
 */
final class ModuleRef : Expression {
public:
    Module mod;

    // Node
    override NodeKind nodeKind() { return NodeKind.MODULE_REF; }
    override bool isResolved() { return true; }

    // Statement
    override Type getType() { return makeUnknownType(); }

    // Expression
    override int precedence() { return Precedence.LOWEST; }

    override string toString() {
        return "ModuleRef [%s]".format(mod.name);
    }
}
