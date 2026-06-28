module ppl7.resolving.resolve_builtin;

import ppl7.all;

void resolveBuiltin(Builtin n, ResolveState state) {

    // Wait for all children to be resolved
    if(!areResolved(n.arguments())) return;

    Expression[] arguments = n.arguments();
    Expression arg0 = arguments[0];

    switch(n.name) {
        case "@debug":
            // Output the Expression to the console
            auto expr = n.first().as!Expression;
            string s = expr.isA!StringLiteral ? expr.as!StringLiteral.stringValue : expr.toString();
            consoleLog("DEBUG: %s", s);

            rewriteToBool(state, n, true);
            break;
        case "@shr":
            rewriteToBinary(state, n, Operator.SHR, arguments[0], arguments[1]);
            break;
        case "@ushr":
            rewriteToBinary(state, n, Operator.USHR, arguments[0], arguments[1]);
            break;
        case "@shl":
            rewriteToBinary(state, n, Operator.SHL, arguments[0], arguments[1]);
            break;
        case "@isArray":
            auto expr = n.first().as!Expression;
            auto result = expr.getType().isA!Array;
            rewriteToBool(state, n, result);
            break;
        case "@isBool":
            auto expr = n.first().as!Expression;
            auto result = expr.getType().isBool();
            rewriteToBool(state, n, result);
            break;
        case "@isConst":
            auto expr = n.first().as!Expression;
            rewriteToBool(state, n, getIsConst(n, expr));
            break;
        case "@isEnum":
            auto expr = n.first().as!Expression;
            auto result = expr.getType().isEnum();
            rewriteToBool(state, n, result);
            break;
        case "@isFunction":
            auto expr = n.first().as!Expression;
            auto result = expr.getType().isFunction();
            rewriteToBool(state, n, result);
            break;
        case "@isInteger":
            auto expr = n.first().as!Expression;
            auto result = expr.getType().isInteger();
            rewriteToBool(state, n, result);
            break;
        case "@isPacked":
            auto expr = n.first().as!Expression;
            if(Struct st = expr.getType().extract!Struct) {
                rewriteToBool(state, n, st.isPacked);
            } else {
                rewriteToBool(state, n, false);
            }
            break;
        case "@isPointer":
            auto expr = n.first().as!Expression;
            auto result = expr.getType().isPointer();
            rewriteToBool(state, n, result);
            break;
        case "@isPublic":
            auto expr = n.first().as!Expression;
            rewriteToBool(state, n, getIsPublic(n, expr));
            break;
        case "@isReal":
            auto expr = n.first().as!Expression;
            auto result = expr.getType().isReal();
            rewriteToBool(state, n, result);
            break;
        case "@isStruct":
            auto expr = n.first().as!Expression;
            auto result = expr.getType().isStruct();
            rewriteToBool(state, n, result);
            break;
        case "@isUnion":
            todo("implement me");
            break;
        case "@isValue":
            auto expr = n.first().as!Expression;
            auto result = !expr.getType().isPointer();
            rewriteToBool(state, n, result);
            break;
        case "@isVoid":
            auto expr = n.first().as!Expression;
            auto result = expr.getType().isVoidValue();
            rewriteToBool(state, n, result);
            break;
        case "@alignOf":
            auto expr = n.first().as!Expression;
            auto align_ = expr.getType().alignment();
            rewriteToInt(state, n, align_);
            break;
        case "@initOf":
            todo("implement me");
            break;
        case "@offsetOf":
            handleOffsetOf(state, n, arg0);
            break;
        case "@sizeOf":
            auto expr = n.first().as!Expression;
            auto size = expr.getType().size();
            rewriteToInt(state, n, size);
            break;
        case "@property":
            handleProperty(state, n);
            break;
        default:
            break;
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

bool getIsConst(Builtin n, Node expr) {
    if(Number num = expr.extractNumber()) return true;
    if(Identifier id = expr.extractIdentifier()) return id.target.isConst();
    if(Index idx = expr.as!Index) return getIsConst(n, idx.expr());
    if(Dot d = expr.as!Dot) return getIsConst(n, d.member());

    semanticError(n, EError.BUILTIN_ISCONST_NOT_IDENTIFIER);
    return false;
}

bool getIsPublic(Builtin n, Node expr) {
    if(Identifier id = expr.extractIdentifier()) return id.target.isPublic();
    if(Index idx = expr.as!Index) return getIsPublic(n, idx.expr());
    if(Dot d = expr.as!Dot) return getIsPublic(n, d.member());

    //writefln("::isPublic expr = %s (%s)", expr, expr.enode());

    // Is it a TypeRef?
    if(TypeRef tr = expr.as!TypeRef) {
        import isp = ppl7.ast.types.Type;
        return isp.isPublic(tr.as!Type);
    }

    // If it is a Type and not a TYpeRef assume it is not public
    if(Type t = expr.as!Type) {
        return false;
    }

    semanticError(n, EError.BUILTIN_ISPUBLIC_NOT_IDENTIFIER_OR_TYPE);
    return false;
}

void handleOffsetOf(ResolveState state, Builtin n, Expression arg0) {
    Dot dot = arg0.as!Dot;

    if(!dot) {
        semanticError(arg0, EError.BUILTIN_OFFSET_OF_NOT_MEMBER);
        return;
    }

    Expression expr = dot.getEndOfChain();

    if(Identifier id = expr.as!Identifier) {

        if(id.target.isVariable()) {
            auto v = id.target.var;
            if(v.isMember()) {
                auto st = v.parent.as!Struct;
                auto index = st.getMemberIndex(v);
                auto offset = st.getOffsetOfMember(index);
                rewriteToLong(state, n, offset);
                return;
            } else {
                semanticError(n, EError.BUILTIN_OFFSET_OF_NOT_MEMBER);
            }
        }

    } else {

        log(state.mod, "expr is %s", n.first().enode());

        semanticError(n, EError.BUILTIN_OFFSET_OF_NOT_IDENTIFIER);
    }
}
void handleProperty(ResolveState state, Builtin n) {
    assert(n.numChildren().isOneOf(2,3));

    Expression[] args = n.arguments();

    // Check that argument[0] is a type
    if(!args[0].isA!Type) {
        semanticError(n, EError.BUILTIN_PROPERTY_MISSING_TYPE);
        return;
    }
    // Check that argument[1] is a StringLiteral
    if(!args[1].isA!StringLiteral) {
        semanticError(args[1], EError.BUILTIN_PROPERTY_MISSING_KEY);
        return;
    }

    // Check that the type is supported
    Type type = args[0].as!Type;
    if(!type.isInteger() && !type.isBool() && !type.isReal()) {
        semanticError(n, EError.BUILTIN_PROPERTY_INVALID_TYPE);
        return;
    }

    bool hasDefault        = n.numChildren() == 3;
    string key             = args[1].as!StringLiteral.stringValue;
    string value           = state.project.options.properties.get(key, null);
    Expression defaultExpr = hasDefault ? args[$-1] : null;

    // If there is no value and no default value then we have an error
    if(value is null && defaultExpr is null) {
        semanticError(args[1], EError.BUILTIN_PROPERTY_NOT_DEFINED);
        return;
    }

    if(value) {
        value = value.toLower();
        rewriteToNumber(state, n, value, type);

    } else {
        // Use the defaultExpr

        if(defaultExpr.as!StringLiteral) {
            value = defaultExpr.as!StringLiteral.stringValue.toLower();
            rewriteToNumber(state, n, value, type);
            return;
        }

        Type defaultType = defaultExpr.getType();

        if(!defaultType.canImplicitlyCastTo(type)) {
            semanticError(defaultExpr, EError.BUILTIN_PROPERTY_INVALID_DEFAULT_VALUE);
            return;
        }

        rewrite(state, n, defaultExpr);
    }
}
