module ppl7.resolving.resolve;

import ppl7.all;

import ppl7.resolving.resolve_array_literal;
import ppl7.resolving.resolve_as;
import ppl7.resolving.resolve_binary;
import ppl7.resolving.resolve_builtin;
import ppl7.resolving.resolve_call;
import ppl7.resolving.resolve_const;
import ppl7.resolving.resolve_identifier;
import ppl7.resolving.resolve_is;
import ppl7.resolving.resolve_if;
import ppl7.resolving.resolve_number;
import ppl7.resolving.resolve_struct_literal;
import ppl7.resolving.resolve_type;
import ppl7.resolving.resolve_variable;

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
        //bool alwaysResolve = n.isA!Variable;
        //if(!alwaysResolve && n.isResolved()) continue;

        if(!n.parent) continue;

        switch(n.enode()) {
            case ENode.ADDRESS_OF: resolveAddressOf(n.as!AddressOf, state); break;
            case ENode.ALIAS: break;
            case ENode.ARRAY_LITERAL: resolveArrayLiteral(n.as!ArrayLiteral, state); break;
            case ENode.ARRAY_TYPE: resolveArray(n.as!Array, state); break;
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
            case ENode.SIMPLE_TYPE: resolveSimpleType(n.as!SimpleType, state); break;
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

struct CallResolveHistory {
    Call call;
    TargetOfCall match;
    TargetOfCall[] nameCandidates;              // All Functions and Variables with the same name

    TargetOfCall[] paramNumCandidates;          // Subset of above where num params is correct
    TargetOfCall[] exactTypeCandidates;         // Subset of above where the argument types exactly match the parameter types
    TargetOfCall[] implicitTypeCandidates;      // Subset of above where the argument types can be implicitly cast to the parameter types
    TargetOfCall[] duplicates;                  // Subset of exact/implicit where the function is an extern(C) and is defined multiple times

    void reset() {
        match = NO_TARGET_OF_CALL;
        nameCandidates.length = 0;
        paramNumCandidates.length = 0;
        exactTypeCandidates.length = 0;
        implicitTypeCandidates.length = 0;
        duplicates.length = 0;
    }
    string toString() {
        return "CallResolveInfo {\n" ~
            "  match             %s\n" ~
            "  nameCandidates    %s\n" ~
            "  paramNumCandidates  %s\n" ~
            "  exactTypeCandidates %s\n" ~
            "  implicitTypeCandidates %s\n" ~
            "  duplicates        %s\n}"
            .format(match != NO_TARGET_OF_CALL ? match.toString() : "none",
                nameCandidates, paramNumCandidates, exactTypeCandidates, implicitTypeCandidates, duplicates);
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void resolveAddressOf(AddressOf n, ResolveState state) {
    if(!n.expr().isResolved()) return;

    // Add explicit cast for &array if not already done
    if(n.expr().getType().isArray()) {
        Array at = n.expr().getType().extract!Array;
        PointerType ptr = makePointerType(at.elementType());

        // Check our parent for existing as
        bool requireRewrite = true;
        if(auto a = n.parent.as!As) {
            if(a.getType().exactlyMatches(ptr)) {
                requireRewrite = false;
            }
        }

        if(requireRewrite) {
            rewriteToAs(state, n, n, ptr);
        }
    }

    // Check for taking the address of a const
    if(n.isResolved()) {
        if(auto id = n.expr().as!Identifier) {
            if(id.target.isVariable() && id.target.var.isConst) {
                semanticError(n, EError.ADDRESS_OF_CONSTANT);
            }
        }
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

    // Rewrite to call ppl_assert
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

    rewriteToCall(state, n, "ppl_assert", [condition, moduleName, moduleFilename, line]);
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
