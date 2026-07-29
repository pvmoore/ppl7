module ppl7.resolving.resolve_binary;

import ppl7.all;

void resolveBinary(Binary n, ResolveState state) {
    if(n.isResolved()) {
        fold(n, state);
        return;
    }

    // Resolve the Type

    auto leftType  = n.left().getType();
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

    if(Type type = selectCommonType(leftType, rightType)) {
        n.type = type;
    } else {
        if(leftType.isPointer() != rightType.isPointer()) {
            semanticError(n, EError.BINARY_POINTER_ARITHMETIC);
            return;
        }

        semanticError(n, EError.BINARY_TYPE_MISMATCH);
    }
}
