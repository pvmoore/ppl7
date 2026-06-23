module ppl7.parsing.parse_types;

import ppl7.all;

/**
 * If this is called then we expect a type otherwise we will raise a syntax error.
 */
void parseType(Node parent, ParseState state) {
    Type type;

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

    if(state.tokenKind() == EToken.LSQUARE) {

        type = parseArrayType(type, state);
        type = consumePointer(type, state);
    }

    parent.add(type);
}

bool isType(ParseState state) {
    return isSimpleType(state) || isAnonStruct(state) || isUserDefinedType(state) || isTypeOf(state) || isFunctionPtr(state);
}
bool isSimpleType(ParseState state) {
    return peekSimpleTypeKind(state) != TypeKind.UNKNOWN;
}
bool isUserDefinedType(ParseState state) {
    if(state.tokenKind() != EToken.IDENTIFIER) return false;
    
    string name = state.text();
    
    // Type
    if(state.mod.isUDT(name, state.mod, null)) return true;

    // moduleAlias.Type
    if(state.mod.isModuleAlias(name) && state.tokenKind(1) == EToken.DOT && state.mod.isUDT(state.text(2), state.mod, name)) {
        return true;
    }

    return false;
}
bool isTypeOf(ParseState state) {
    return state.tokenKind() == EToken.COLON2 && state.peek(1).text == "typeOf";
}
bool isAnonStruct(ParseState state) {
    return state.text() == "struct" && state.tokenKind(1) == EToken.LBRACE;
}
/**
 * fn(params)->void 
 */
bool isFunctionPtr(ParseState state) {
    if(!state.matches(0, EToken.IDENTIFIER, EToken.LPAREN)) return false;
    int closing = state.findOffsetOfClosing(1, EToken.LPAREN, EToken.RPAREN);
    if(closing == -1) return false;
    return state.peek(closing+1).kind == EToken.RARROW;
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

Type consumePointer(Type type, ParseState state) {
    while(state.tokenKind() == EToken.STAR) {
        type = makePointerTypeWithChild(type);
        state.next();
    }
    return type;
}

TypeKind peekSimpleTypeKind(ParseState state) {
    switch(state.text()) {
        case "bool": return TypeKind.BOOL;
        case "byte": return TypeKind.BYTE;
        case "short": return TypeKind.SHORT;
        case "int": return TypeKind.INT;
        case "long": return TypeKind.LONG;
        case "float": return TypeKind.FLOAT;
        case "double": return TypeKind.DOUBLE;
        case "void": return TypeKind.VOID;
        case "...": return TypeKind.C_VARARGS;
        default: return TypeKind.UNKNOWN;
    }
    assert(false);
}

/**
 * '::' 'typeOf' '(' Expression ')'
 */
Type parseTypeOf(ParseState state) {

    auto b = makeNode!TypeOf(state);

    state.skip(EToken.COLON2);

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
    TypeKind tk = peekSimpleTypeKind(state);
    if(tk == TypeKind.UNKNOWN) return null;

    SimpleType type = makeNode!SimpleType(state);
    type.setTypeKind(tk);
    state.next();
    return type;
}

Type parseAnonStruct(ParseState state) {
    Struct s = makeNode!Struct(state);
    state.skip("struct");
    state.skip(EToken.LBRACE);

    while(state.tokenKind() != EToken.RBRACE) {
        parseVariable(s, state, false);

        if(state.tokenKind().isOneOf(EToken.SEMICOLON, EToken.COMMA)) {
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

    if(state.mod.isModuleAlias(state.text()) && state.tokenKind(1) == EToken.DOT) {

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
Type parseArrayType(Expression type, ParseState state) {
    assert(state.tokenKind() == EToken.LSQUARE);

    ArrayType a = makeNode!ArrayType(state);
    a.add(type);

    // [
    state.skip(EToken.LSQUARE);

    // Length Expression
    parseExpression(a, state);

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
    while(state.tokenKind() != EToken.RPAREN) {
        parseParameter(f, state);
        f.numParams++;

        // ,
        if(state.tokenKind() == EToken.COMMA) {
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

