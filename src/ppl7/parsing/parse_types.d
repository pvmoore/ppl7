module ppl7.parsing.parse_types;

import ppl7.all;

/**
 * If this is called then we expect a type otherwise we will raise a syntax error.
 */
void parseType(Node parent, ParseState state) {
    Type type;

    bool isImmutable = state.text() == "immutable";
    if(isImmutable) state.next();

    if(isTypeOf(state)) {
        type = parseTypeOf(state);
    } else if(isSimpleType(state)) {
        type = parseSimpleType(state);
    } else if(isAnonStruct(state)) {
        type = parseAnonStruct(state);
    } else if(isUserDefinedType(state)) {
        type = parseUserDefinedType(state);
    } else if(isFunctionPtr(state)) {
        type = parseFunctionPtr(state);
    }

    if(!type) {
        syntaxError(state, "Expected type");
    }

    type = consumePointer(type, state);

    if(state.etoken() == EToken.LSQUARE) {

        type = parseArray(type, state);
        type = consumePointer(type, state);
    }

    // Add immutable property to the type
    if(auto p = type.extract!PointerType) {
        p.isImmutable = isImmutable;
    } else if(auto a = type.extract!Array) {
        a.isImmutable = isImmutable;
    } else if(isImmutable) {
        semanticError(parent, EError.TYPE_CANNOT_BE_IMMUTABLE);
    }

    parent.add(type);
}

bool isType(ParseState state) {
    if(state.text() == "immutable") return true;
    return isSimpleType(state) || isAnonStruct(state) || isUserDefinedType(state) || isTypeOf(state) || isFunctionPtr(state);
}
bool isSimpleType(ParseState state) {
    return peekSimpleEType(state) != EType.UNKNOWN;
}
bool isUserDefinedType(ParseState state) {
    if(state.etoken() != EToken.IDENTIFIER) return false;

    string name = state.text();

    // Type
    if(state.mod.isUDT(name, state.mod, null)) return true;

    // moduleAlias.Type
    if(state.mod.isModuleAlias(name) && state.etoken(1) == EToken.DOT && state.mod.isUDT(state.text(2), state.mod, name)) {
        return true;
    }

    return false;
}
bool isTypeOf(ParseState state) {
    return (state.etoken() == EToken.AT && state.peek(1).text == "typeOf");
}
bool isAnonStruct(ParseState state) {
    return state.text() == "struct" && state.etoken(1) == EToken.LBRACE;
}
/**
 * fn(params)->void
 */
bool isFunctionPtr(ParseState state) {
    if(!state.matches(0, EToken.IDENTIFIER, EToken.LPAREN)) return false;
    int closing = state.findOffsetOfClosing(1, EToken.LPAREN, EToken.RPAREN);
    if(closing == -1) return false;
    return state.peek(closing+1).etoken == EToken.RARROW;
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

Type consumePointer(Type type, ParseState state) {
    while(state.etoken() == EToken.STAR) {
        type = makePointerTypeWithChild(type);
        state.next();
    }
    return type;
}

EType peekSimpleEType(ParseState state) {
    switch(state.text()) {
        case "bool": return EType.BOOL;
        case "byte": return EType.BYTE;
        case "short": return EType.SHORT;
        case "int": return EType.INT;
        case "long": return EType.LONG;
        case "float": return EType.FLOAT;
        case "double": return EType.DOUBLE;
        case "void": return EType.VOID;
        case "...": return EType.C_VARARGS;
        default: return EType.UNKNOWN;
    }
    assert(false);
}

/**
 * '@' 'typeOf' '(' Expression ')'
 */
Type parseTypeOf(ParseState state) {

    auto b = makeNode!TypeOf(state);

    state.skip(EToken.AT);

    state.skip("typeOf");

    state.skip(EToken.LPAREN);

    parseExpressionWithUpperBound(b, state);

    state.skip(EToken.RPAREN);

    return b;
}

/**
 * 'byte' | 'int' etc...
 */
Type parseSimpleType(ParseState state) {
    EType tk = peekSimpleEType(state);
    if(tk == EType.UNKNOWN) return null;

    SimpleType type = makeNode!SimpleType(state);
    type.setEType(tk);
    state.next();
    return type;
}

/**
 * struct '{' { Type [ name ] [','] } '}'
 */
Type parseAnonStruct(ParseState state) {
    Struct s = makeNode!Struct(state);
    state.skip("struct");
    state.skip(EToken.LBRACE);

    if(state.hasAttribute("packed")) {
        s.isPacked = true;
    }

    while(state.etoken() != EToken.RBRACE) {
        parseVariable(s, state, false);

        // optional comma
        if(state.etoken() == EToken.COMMA) {
            state.next();
        }
    }

    state.skip(EToken.RBRACE);
    return s;
}

/**
 * name
 * moduleAlias.name
 */
Type parseUserDefinedType(ParseState state) {
    assert(isUserDefinedType(state));

    if(state.mod.isModuleAlias(state.text()) && state.etoken(1) == EToken.DOT) {

        Module m = state.mod.importedModulesQualified[state.text()];
        state.next();
        state.skip(EToken.DOT);

        TypeRef tr = makeNode!TypeRef(state);
        tr.name = state.text(); state.next();
        tr.fromModule = m;
        return tr;
    }

    // TypeRef, union, enum or alias
    TypeRef tr = makeNode!TypeRef(state);
    tr.name = state.text(); state.next();
    return tr;
}

/**
 * '[' Expression ']'
 */
Type parseArray(Expression type, ParseState state) {
    assert(state.etoken() == EToken.LSQUARE);

    Array a = makeNode!Array(state);
    a.add(type);

    // [
    state.skip(EToken.LSQUARE);

    // Length Expression
    if(state.etoken() == EToken.RSQUARE) {
        // This is an array type with no length. Add a dummy length and a semantic error.
        a.add(makeIntNumber(0, makeIntType()));
        semanticError(state, a, EError.ARRAY_MISSING_LENGTH);
    } else {
        parseExpression(a, state);
    }

    // ]
    state.skip(EToken.RSQUARE);

    return a;
}

/**
 * 'fn' '(' params ')' '->' Type
 */
Type parseFunctionPtr(ParseState state) {

    Function f = makeNode!Function(state);

    state.skip("fn");

    // Parameters
    state.skip(EToken.LPAREN);
    while(state.etoken() != EToken.RPAREN) {
        parseParameter(f, state);
        f.numParams++;

        // ,
        if(state.etoken() == EToken.COMMA) {
            state.skip(EToken.COMMA);
        }
    }
    state.skip(EToken.RPAREN);

    state.skip(EToken.RARROW);

    // Return type
    parseType(f, state);

    // Move the return type to the front
    if(f.numChildren() > 1) {
        Node returnType = f.last();
        f.addToFront(returnType);
    }

    return f;
}

