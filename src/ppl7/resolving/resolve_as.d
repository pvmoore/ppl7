module ppl7.resolving.resolve_as;

import ppl7.all;

void resolveAs(As n, ResolveState state) {
    if(n.isResolved()) return;

    Type lt = n.leftType();
    Type rt = n.rightType();
    assert(lt);
    assert(rt);

    if(!lt.isResolved() || !rt.isResolved()) return;

    checkExplicitCast(n, lt, rt, state);

    // fold

    if(n.isResolved() && !state.project.hasErrors()) {

        if(auto num = n.expr().as!Number) {
            if(rt.isA!SimpleType) {
                // We can convert the Number to the correct type now and remove the As node

                num.setType(rt);

                rewrite(state, n, n.expr());
                return;
            }
        }
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void checkExplicitCast(As n, Type lt, Type rt, ResolveState state) {

    if(lt.exactlyMatches(rt)) {
        // todo - rewrite to remove the As node because it is not necessary
        n.resolveEvaluated = true;
        return;
    }

    if(lt.isPointer() && rt.isPointer()) {
        // For now, allow any pointer to pointer conversion
        n.resolveEvaluated = true;
        return;
    }

    if(lt.isPointer() && rt.isValue()) {
        // Thie is ok if the right type is integer
        if(!rt.isInteger()) {
            semanticError(n, EError.CAST_INVALID);
            return;
        }
    }
    if(lt.isValue() && rt.isPointer()) {
        // This is ok if left type is an integer
        if(!lt.isInteger()) {
            semanticError(n, EError.CAST_INVALID);
            return;
        }
    }

    if(lt.isEnum() && rt.isEnum()) {
        Enum leftEnum = lt.extract!Enum;
        Enum rightEnum = rt.extract!Enum;
        assert(leftEnum != rightEnum);

        // These must be different enums. Allow this if the element types are convertable
        checkExplicitCast(n, leftEnum.elementType(), rightEnum.elementType(), state);
        return;
    }

    if(auto e = lt.extract!Enum) {
        checkExplicitCast(n, e.elementType(), rt, state);
        return;
    }

    if(auto e = rt.extract!Enum) {
        checkExplicitCast(n, lt, e.elementType(), state);
        return;
    }

    if(lt.isStruct() && rt.isStruct()) {
        assert(lt.isValue() && rt.isValue());

        // Both sides are structs but they are not exact matches

        // Techcically we could allow this if all of the following are true:
        //  - The sizes are the same
        //  - The number of members is the same
        //  - The members can be implicitly cast
        // but for now we will disallow this since it is unlikely to be useful and is not very efficient.

        semanticError(n, EError.CAST_INVALID);
        return;
    }

    if(lt.isStruct() && !rt.isStruct()) {
        // Casting from a struct to a non-struct
        semanticError(n, EError.CAST_INVALID);
        return;
    }

    if(!lt.isStruct() && rt.isStruct()) {
        // Casting from a non-struct to a struct
        semanticError(n, EError.CAST_INVALID);
        return;
    }

    n.resolveEvaluated = true;
}
