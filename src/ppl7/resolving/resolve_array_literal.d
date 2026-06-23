module ppl7.resolving.resolve_array_literal;

import ppl7.all;

void resolveArrayLiteral(ArrayLiteral n, ResolveState state) {

    // Use the parent type if available.

    Type parentType = state.resolveTypeFromParent(n);
    if(parentType.isResolved()) {
        n.setType(parentType);
        return;
    }

    // Special case if we think the parent will never produce a type
    if(n.parent.nodeKind() == NodeKind.BUILTIN) {
        n.setType(getTypeFromElements(n, state));
    }
}

private:

/** Generate the ArrayType assuming we cannot determine the type from the parent */
Type getTypeFromElements(ArrayLiteral n, ResolveState state) {
    
    // If we have no elements, then the type is int[0]
    if(n.elements().length == 0) return makeArrayType(makeIntType(), 0);

    Type elementType = n.first().as!Expression.getType();
    if(!elementType.isResolved()) return makeUnknownType();

    return makeArrayType(elementType, n.elements().length.as!uint);
}
