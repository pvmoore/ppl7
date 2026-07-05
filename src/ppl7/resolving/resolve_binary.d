module ppl7.resolving.resolve_binary;

import ppl7.all;

void resolveBinary(Binary n, ResolveState state) {
    if(!n.type.isResolved()) {
        // Resolve the Type

        auto leftType = n.left().getType();
        auto rightType = n.right().getType();

        if(!leftType.isResolved() || !rightType.isResolved()) return;

        if(n.op.isAssign()) {
            n.type = leftType;
            return;
        }

        if(n.op.isBool()) {
            n.type = makeBoolType();
            return;
        }

        n.type = selectCommonType(n.left().getType(), n.right().getType());
    }
}
