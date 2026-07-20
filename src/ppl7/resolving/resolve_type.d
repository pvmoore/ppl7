module ppl7.resolving.resolve_type;

import ppl7.all;
import ppl7.resolving.resolve_const;

void resolveSimpleType(SimpleType n, ResolveState state) {
    // Nothing to do
}

void resolveArray(Array n, ResolveState state) {
    if(n.isResolved()) return;

    resolveConstNumber(n.numElementsExpr(), state);
}

void resolveEnum(Enum n, ResolveState state) {
    if(n.isResolved()) return;

    Type elementType = n.elementType();

    assert(elementType.isResolved());

    // Update the member values (for integer or real enums)

    // If the enum type is not integer or real then every member must have an initialiser
    if(!elementType.isInteger() && !elementType.isReal()) {
        if(!n.allMembersHaveInitialisers()) {
            semanticError(n, EError.ENUM_MISSING_INITIALISERS);
        }
        n.resolveEvaluated = true;
        return;
    }

    // The element type is an integer or real. Generate any missing initialisers
    assert(elementType.isInteger() || elementType.isReal());

    string stringValue = "0";
    foreach(i, m; n.members()) {

        if(m.hasInitialiser()) {

            if(auto nl = m.value().as!Null) {
                if(!elementType.isPointer()) {
                    semanticError(m.value(), EError.ENUM_MEMBER_TYPE_MISMATCH);
                    return;
                }
            }

            if(!m.value().isResolved()) {
                // Wait for the initialiser to be resolved
                return;
            }

            // Set value to the initialiser value
            if(Number num = m.value().as!Number) {

                stringValue = num.stringValue;

            } else {
                // We can't evaluate this yet. Bail out and try again in the next pass
                return;
            }

            // if(!m.value().getType().exactlyMatches(elementType)) {
            if(!m.value().getType().canImplicitlyCastTo(elementType)) {
                semanticError(m.value(), EError.ENUM_MEMBER_TYPE_MISMATCH);
                return;
            }

        } else {
            // Create a new Number node with the correct value
            Number num = makeNumber(stringValue, elementType);
            m.add(num);
        }

        // Increment the value

        //todo - use num.add(1)
        import std.conv : to;
        stringValue = "%s".format(stringValue.to!double + 1.0);
    }

    n.resolveEvaluated = true;
}

void resolveTypeOf(TypeOf n, ResolveState state) {
    if(n.isResolved()) return;
    if(!n.expr().isResolved()) return;

    Type type = n.expr().getType();

    rewriteToTypeRef(state, n, type);
}

void resolveTypeRef(TypeRef n, ResolveState state) {
    if(n.isResolved()) return;

    Module mod = state.mod;
    bool includeImports = true;
    bool requirePublic = false;

    if(n.fromModule) {
        mod = n.fromModule;
        includeImports = false;
        requirePublic = true;
    }

    if(auto t = mod.getUDT(n.name, includeImports)) {
        if(requirePublic) {
            if(!isPublic(t)) {
                warn(n, "Type %s is not public".format(n.name));
                return;
            }
        }
        n.type = t;
    }
}
