module ppl7.resolving.resolve;

import ppl7.all;

void resolve(ResolveState state) {
    updateLoggingContext(state.mod, LoggingStage.Resolving);
    state.mod.log("Resolving module (pass %s)", state.numIterations+1);
    resolveChildren(state.mod, state);
}

void resolveChildren(Node parent, ResolveState state) {
    foreach(n; parent.children) {

        // resolve from the bottom up
        if(n.hasChildren()) {
            resolveChildren(n, state);
        }

        // Always resolve Variable in case it needs to rewrite its initialiser
        bool alwaysResolve = n.isA!Variable;

        if(!alwaysResolve && n.isResolved()) continue;

        switch(n.enode()) {
            case ENode.ADDRESS_OF: resolveAddressOf(n.as!AddressOf, state); break;
            case ENode.ALIAS: break;
            case ENode.ARRAY_LITERAL: resolveArrayLiteral(n.as!ArrayLiteral, state); break;
            case ENode.ARRAY_TYPE: resolveArrayType(n.as!ArrayType, state); break;
            case ENode.AS: resolveAs(n.as!As, state); break;
            case ENode.ASSERT: resolveAssert(n.as!Assert, state); break;
            case ENode.BINARY: resolveBinary(n.as!Binary, state); break;
            case ENode.BUILTIN: resolveBuiltin(n.as!Builtin, state); break;
            case ENode.CALL: resolveCall(n.as!Call, state); break;
            case ENode.DOT: break;
            case ENode.ENUM: resolveEnum(n.as!Enum, state); break;
            case ENode.ENUM_MEMBER: break;
            case ENode.FUNCTION: break;
            case ENode.IDENTIFIER: resolveIdentifier(n.as!Identifier, state); break;
            case ENode.IF: resolveIf(n.as!If, state); break;
            case ENode.INDEX: break;
            case ENode.IS: resolveIs(n.as!Is, state); break;
            case ENode.MODULE_REF: break;
            case ENode.NODE_REF: break;
            case ENode.NUMBER: resolveNumber(n.as!Number, state); break;
            case ENode.NULL: resolveNull(n.as!Null, state); break;
            case ENode.PARENS: break;
            case ENode.POINTER_TYPE: break;
            case ENode.RETURN: break;
            case ENode.STRING_LITERAL: resolveStringLiteral(n.as!StringLiteral, state); break;
            case ENode.STRUCT: break;
            case ENode.STRUCT_LITERAL: resolveStructLiteral(n.as!StructLiteral, state); break;
            case ENode.TYPE_OF: resolveTypeOf(n.as!TypeOf, state); break;
            case ENode.TYPE_REF: resolveTypeRef(n.as!TypeRef, state); break;
            case ENode.UNARY: break;
            case ENode.VALUE_OF: break;
            case ENode.VARIABLE: resolveVariable(n.as!Variable, state); break;
            default: assert(false, "Handle resolve(%s)".format(n.enode()));
        }

        // At this point Node n may no longer be attached
        if(!n.parent) continue;

        if(!n.isResolved()) {
            state.setUnresolved(n);
        }
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void resolveAddressOf(AddressOf n, ResolveState state) {
    if(!n.expr().isResolved()) return;



    if(n.expr().getType().isArrayType()) {
        // Add explicit cast for &array
        ArrayType at = n.expr().getType().extract!ArrayType;
        PointerType ptr = makePointerType(at.elementType());
        rewriteToAs(state, n, n, ptr);
    }

    n.setResolveEvaluated();
}

void resolveAssert(Assert n, ResolveState state) {
    // Rewrite to bool true if asserts are not enabled
    if(!state.mod.project.options.enableAsserts) {
        rewriteToBool(state, n, true);
        return;
    }

    if(!n.first().isResolved()) return;

    // Rewrite to call @assert
    auto condition = n.first().as!Expression;
    auto moduleName = makeStringLiteral(state.mod.name, true);
    auto moduleFilename = makeStringLiteral(state.mod.relFilename, true);
    uint lineNumber = n.startToken.line + 1;
    auto line = makeIntNumber(lineNumber);

    Type conditionType = condition.getType();
    if(conditionType.isBool()) {
        // Already good
    } else if(conditionType.isPointer()) {
        condition = makeBinary(Operator.NOT_EQUAL, condition, makeNull(conditionType), makeBoolType());
    } else {
        condition = makeBinary(Operator.NOT_EQUAL, condition, makeLongNumber(0), makeBoolType());
    }

    rewriteToCall(state, n, "@assert", [condition, moduleName, moduleFilename, line]);
}

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

void resolveNull(Null n, ResolveState state) {
    n.setType(state.resolveTypeFromParent(n));
}

void resolveStringLiteral(StringLiteral n, ResolveState state) {
    // Convert escape sequences to their actual values
    string result;
    int pos = 0;
    string s = n.stringValue;
    while(pos < s.length) {
        auto t = state.resolveChar(n, s[pos..$]);
        uint value = t[0];
        uint len = t[1];

        result ~= value.as!char;
        pos += len;
    }
    n.stringValue = result;
    n.resolveEvaluated = true;
}
