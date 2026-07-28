module ppl7.parsing.parse_statements;

import ppl7.all;


void parseStatementsAtModuleScope(ParseState state) {

    updateLoggingContext(state.mod, LoggingStage.Parsing);

    state.mod.log("Parsing module");

    // Loop until all tokens are consumed or an error is found
    while(!state.eof() && !state.project.hasErrors()) {
        parseStatementAtModuleScope(state);
    }
}
/**
 * Statements allowed at Module scope:
 *   - Import
 *   - Struct
 *   - Alias
 *   - Enum
 *   - Union    *todo
 *
 *   - Function ::= fn foo(Types) -> Type {}
 *   - Variable ::= Type name = Expression
 */
void parseStatementAtModuleScope(ParseState state) {
    Module mod = state.mod;

    state.attributes.parse(state);

    // We can run out of statements here if the last thing was an #end
    if(state.eof()) return;

    // Consume public, private
    bool isPublic = parseVisibility(state, true, true);

    // Variable
    if(isType(state) || "const" == state.text()) {
        parseVariable(mod, state, isPublic);
    } else switch(state.etoken()) {
        case EToken.IDENTIFIER:
            switch(state.text()) {
                case "extern":
                case "fn":
                    parseFunction(mod, state, isPublic);
                    break;
                case "alias":
                    parseAlias(mod, state, isPublic);
                    break;
                case "enum":
                    parseEnum(mod, state, isPublic);
                    break;
                case "struct":
                    parseStruct(mod, state, isPublic);
                    break;
                case "import":
                    parseImport(mod, state, isPublic);
                    break;
                default:
                    syntaxError(state, "Expected statement but found %s".format(state.token()));
                    break;
            }
            break;
        default:
            syntaxError(state, "Expected statement but found %s".format(state.token()));
            break;
    }
}

/**
 * Statements allowed at Function scope:
 *   - Assert
 *   - Return
 *   - Variable
 *   - While        *todo
 *   - For          *todo
 *   - Expression
 */
void parseStatementAtFunctionScope(Statement parent, ParseState state) {

    state.attributes.parse(state);

    if(state.etoken() == EToken.RBRACE) return;

    // Variable
    if(isType(state) || "const" == state.text()) {
        parseVariable(parent, state, false);
        return;
    }

    switch(state.etoken()) {
        case EToken.IDENTIFIER:
            if("return" == state.text()) {
                parseReturn(parent, state);
                return;
            }
            if("assert" == state.text()) {
                parseAssert(parent, state);
                return;
            }
            if("for" == state.text()) {
                parseFor(parent, state);
                return;
            }
            if("break" == state.text()) {
                parseBreak(parent, state);
                return;
            }
            if("continue" == state.text()) {
                parseContinue(parent, state);
                return;
            }
            break;
        default:
            break;
    }

    // If we get here then it must be an Expression
    parseExpression(parent, state);
}

//──────────────────────────────────────────────────────────────────────────────────────────────────

/**
 * Consume visibility tokens if present.
 * Return true if public
 */
bool parseVisibility(ParseState state, bool atModuleScope, bool modifiersHereAreValid) {
    bool isPublic = atModuleScope ? state.insidePublicScopeModule : state.insidePublicScopeStruct;

    void check() {
        if(!modifiersHereAreValid) {
            syntaxError(state, "Visibility modifiers are not allowed here");
        }
    }

    while(!state.eof()) {
        if(state.text() == "public") {
            check();
            state.next();

            if(state.etoken() == EToken.COLON) {
                state.next();
                if(atModuleScope) state.insidePublicScopeModule = true;
                else state.insidePublicScopeStruct = true;
            }
            isPublic = true;

        } else if(state.text() == "private") {
            check();
            state.next();

            if(state.etoken() == EToken.COLON) {
                state.next();
                if(atModuleScope) state.insidePublicScopeModule = false;
                else state.insidePublicScopeStruct = false;
            }

            isPublic = false;
        } else {
            break;
        }
    }
    return isPublic;
}

/**
 * 'alias' name '=' Type
 */
void parseAlias(Node parent, ParseState state, bool isPublic) {
    auto a = makeNode!Alias(state);
    parent.add(a);

    a.isPublic = isPublic || state.hasAttribute("public");

    state.skip("alias");

    a.name = state.text(); state.next();

    state.skip(EToken.EQUAL);

    parseType(a, state);
}

/**
 * 'assert' '(' Expression ')'
 */
void parseAssert(Node parent, ParseState state) {
    auto a = makeNode!Assert(state);
    parent.add(a);

    state.skip("assert");

    parseExpression(a, state);
}

/**
 * 'break' [ number ]
 */
void parseBreak(Node parent, ParseState state) {
    auto b = makeNode!Break(state);
    parent.add(b);

    state.skip("break");

    if(state.isOnSameLine() && state.etoken() != EToken.SEMICOLON) {
        parseExpression(b, state);
    } else {
        // Add default number
        b.add(makeIntNumber(1));
    }
}

/**
 * 'continue' [ number ]
 */
void parseContinue(Node parent, ParseState state) {
    auto c = makeNode!Continue(state);
    parent.add(c);

    state.skip("continue");

    if(state.isOnSameLine() && state.etoken() != EToken.SEMICOLON) {
        parseExpression(c, state);
    } else {
        // Add default number
        c.add(makeIntNumber(1));
    }
}

/**
 * ENUM        ::= 'enum' name [ ':' Type ] '{' { ENUM_MEMBER } '}'
 * ENUM_MEMBER ::= name [ '=' Expression ]
 */
void parseEnum(Node parent, ParseState state, bool isPublic) {
    auto e = makeNode!Enum(state);
    parent.add(e);

    e.isPublic = isPublic || state.hasAttribute("public");
    e.isUnqualified = state.hasAttribute("unqualified");

    state.skip("enum");

    e.name = state.text(); state.next();

    if(state.etoken() == EToken.COLON) {
        state.skip(EToken.COLON);
        parseType(e, state);
    } else {
        e.add(makeSimpleType(EType.INT));
    }

    state.skip(EToken.LBRACE);

    while(state.etoken() != EToken.RBRACE) {

        if(state.etoken() != EToken.IDENTIFIER) {
            syntaxError(state, "Expected identifier");
        }

        auto em = makeNode!EnumMember(state);
        e.add(em);

        em.name = state.text(); state.next();

        if(state.etoken() == EToken.EQUAL) {
            state.skip(EToken.EQUAL);
            parseExpression(em, state);
        }

        if(state.etoken().isOneOf(EToken.SEMICOLON, EToken.COMMA)) {
            state.next();
        }
    }

    state.skip(EToken.RBRACE);
}

/**
 * fn foo(Types) -> Type {}
 */
void parseFunction(Module mod, ParseState state, bool isPublic) {
    auto f = makeNode!Function(state);
    mod.add(f);

    f.isPublic = isPublic || state.hasAttribute("public");

    if(string alias_ = state.getAttribute("name").value) {
        f.alias_ = alias_;
    }

    if(state.hasAttribute("ABI")) {
        string value = state.getAttribute("ABI").value;
        if(value.isOneOf("C", "WIN64")) {
            f.callingConvention = value;
        } else {
            syntaxError(state, "Unrecognised ABI '%s'".format(value));
        }
    }

    if(state.hasAttribute("noinline")) {
        f.noinline = true;
    }

    // fn
    state.skip("fn");

    // Name
    f.name = state.token().text; state.next();

    if(mod.isMainModule) {
        f.isMain = f.name == "main";
    }

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

    // Return type
    if(state.etoken() == EToken.RARROW) {
        state.skip(EToken.RARROW);

        parseType(f, state);
    } else {
        if(f.isMain) {
            f.add(makeSimpleType(EType.INT));
        } else {
            // Assume return void
            f.add(makeSimpleType(EType.VOID));
        }
    }

    // Move the return type to the front
    if(f.numChildren() > 1) {
        Node returnType = f.last();
        f.addToFront(returnType);
    }

    // Body (optional if this is an extern function)
    if(state.etoken() == EToken.LBRACE) {
        state.skip(EToken.LBRACE);
        while(state.etoken() != EToken.RBRACE) {
            parseStatementAtFunctionScope(f, state);
        }
        state.skip(EToken.RBRACE);
    } else {
        f.isExtern = true;
    }

    if(f.isMain || (f.isExtern && !f.callingConvention)) {
        f.callingConvention = "C";
    }

    if(f.isMain) {
        // add implicit return 0 at the end of the function if we don't see one
        auto bodyStmts = f.bodyStatements();
        if(bodyStmts.length == 0 || !bodyStmts.last().isA!Return) {
            auto ret = makeNode!Return(state);
            ret.add(makeIntNumber(0));
            f.add(ret);
        }
    }
}

/**
 * [ 'const' ] Type [ name ]
 */
void parseParameter(Function parent, ParseState state) {

    Variable v = makeNode!Variable(state);
    parent.add(v);

    v.vkind = VariableKind.PARAMETER;
    v.isConst = state.text() == "const";
    if(v.isConst) state.next();

    // Type
    parseType(v, state);

    Type type = v.last().as!Statement.getType();
    if(type.etype() == EType.C_VARARGS) {
        parent.hasVarargParam = true;
    }

    // name
    if(state.etoken() != EToken.COMMA && state.etoken() != EToken.RPAREN) {
        v.name = state.token().text; state.next();
    }
}

/**
 * [ 'const' ] Type name [ '=' Expression ]
 */
void parseVariable(Node parent, ParseState state, bool isPublic) {

    auto v = makeNode!Variable(state);
    parent.add(v);

    v.isPublic = isPublic || state.hasAttribute("public");
    v.isConst = state.text() == "const";
    if(v.isConst) {
        state.next();

        if(Struct st = parent.as!Struct) {
            if(!st.isNamed()) {
                // Anon structs cannot have const members
                semanticError(state.project, state.mod, v, EError.VARIABLE_ANON_STRUCT_CONST);
            }
        }
    }

    string abi;

    if(state.hasAttribute("ABI")) {
        abi = state.getAttribute("ABI").value;
    }

    // Type
    parseType(v, state);

    if(abi) {
        assert(v.getType().isFunction());
        v.getType().extract!Function.callingConvention = abi;
    }

    if(state.etoken() == EToken.IDENTIFIER && !isType(state)) {
        v.name = state.token().text; state.next();
    }

    if(v.parent.isA!Function) {
        v.vkind = VariableKind.LOCAL;
    } else if(v.parent.isA!Struct) {
        v.vkind = VariableKind.MEMBER;
    } else {
        v.vkind = VariableKind.GLOBAL;
    }

    // Initialiser
    if(state.etoken() == EToken.EQUAL) {
        state.skip(EToken.EQUAL);
        parseExpression(v, state);
    } else if(v.isConst) {

        if(Struct st = parent.as!Struct) {
            // Don't complain yet. Check later to see if this is set to something
            return;
        }

        semanticError(v, EError.VARIABLE_CONST_NO_INITIALISER);
    }
}

/**
 * 'return' [ Expression ]
 */
void parseReturn(Statement parent, ParseState state) {
    Return r = makeNode!Return(state);
    parent.add(r);

    state.skip("return");

    // If there is something on the same line then assume it is an expression
    if(state.isOnSameLine() && state.etoken() != EToken.SEMICOLON) {
        parseExpression(r, state);
    }
}

/**
 * 'struct' name '{' { Variable } '}'
 */
void parseStruct(Node parent, ParseState state, bool isPublic) {
    Struct s = makeNode!Struct(state);
    parent.add(s);

    s.isPublic = isPublic || state.hasAttribute("public");

    if(state.hasAttribute("packed")) {
        s.isPacked = true;
    }

    state.skip("struct");

    s.name = state.token().text; state.next();

    state.skip(EToken.LBRACE);

    while(state.etoken() != EToken.RBRACE) {

        // Consume public, private
        bool isPublicMember = parseVisibility(state, false, s.isNamed());

        // Anon struct members are always public
        if(!s.isNamed()) {
            isPublicMember = true;
        }

        parseVariable(s, state, isPublicMember);

        if(state.etoken().isOneOf(EToken.SEMICOLON, EToken.COMMA)) {
            state.next();
        }
    }

    state.skip(EToken.RBRACE);
}

/**
 * 'import' [ name '=' ] [ libname ':' ] moduleName { '/' moduleName }
 */
void parseImport(Node parent, ParseState state, bool isPublic) {
    // Just parse and throw away this info since we have already scanned it

    // todo - implement public imports

    state.skip("import");

    // Alias
    if(state.peek(1).etoken == EToken.EQUAL) {
        string name = state.text(); state.next();
        state.skip(EToken.EQUAL);
    }

    // Library
    if(state.peek(1).etoken == EToken.COLON) {
        string libName = state.text(); state.next();
        state.skip(EToken.COLON);
    }

    string moduleName = state.text(); state.next();

    while(state.etoken() == EToken.SLASH) {
        state.skip(EToken.SLASH);
        moduleName ~= "/";
        moduleName ~= state.text(); state.next();
    }

    state.mod.log("importing %s", moduleName);
}

/**
 * FOR          ::= 'for' [Variable ','] SEQUENCE '{' { Statement } '}'
 * FORWARD_SEQ  ::= Expression '..' ( '<' | '=' ) Expression
 * REVERSE_SEQ  ::= Expression ( '>' | '=' ) '..' Expression
 * WHILE_SEQ    ::= Expression
 * SEQUENCE     ::= FORWARD_SEQ | REVERSE_SEQ | WHILE_SEQ
 */
void parseFor(Statement parent, ParseState state) {
    state.skip("for");

    For f = makeNode!For(state);
    parent.add(f);

    // optional counter
    if(isType(state)) {
        f.hasCounter = true;
        auto counter = makeNode!Variable(state);
        f.add(counter);

        parseType(counter, state);

        counter.name = state.text(); state.next();
        counter.vkind = VariableKind.LOCAL;

    } else {
        // Is it a variable identifier?
        if(state.matches(0, EToken.IDENTIFIER, EToken.COMMA) ||
           state.matches(0, EToken.IDENTIFIER, EToken.EQUAL))
        {
            f.hasCounter = true;
            auto counter = makeNode!Variable(state);
            f.add(counter);

            counter.add(makeIntType());

            counter.name = state.text(); state.next();
            counter.vkind = VariableKind.LOCAL;
        }
    }

    if(f.hasCounter) {
        if(state.etoken() == EToken.EQUAL) {
            state.skip(EToken.EQUAL);
            parseExpression(f.counter(), state);

            semanticError(f, EError.FOR_COUNTER_ASSIGNMENT);
        }
        state.skip(EToken.COMMA);
    }

    // The first expression must always exist but could be either:
    //   (1) start or
    //   (2) condition
    parseExpression(f, state);

    void parseEnd() {
        // end
        parseExpression(f, state);
    }

    if(state.matches(0, EToken.DOT2)) {
        semanticError(state, f, EError.FOR_MISSING_INCLUSIVE_EXCLUSIVE);

    } else if(state.matches(0, EToken.DOT2_LANGLE)) {
        // forward sequence, exclusive
        state.skip(EToken.DOT2_LANGLE);

        parseEnd();

    } else if(state.matches(0, EToken.DOT2_EQUAL)) {
        // forward sequence, inclusive
        state.skip(EToken.DOT2_EQUAL);
        f.isInclusive = true;

        parseEnd();

    } else if(state.matches(0, EToken.RANGLE_DOT2)) {
        // reverse sequence, exclusive
        f.isReversed = true;
        state.skip(EToken.RANGLE_DOT2);

        parseEnd();

    } else if(state.matches(0, EToken.EQUAL_DOT2)) {
        // reverse sequence, inclusive
        f.isReversed = true;
        f.isInclusive = true;
        state.skip(EToken.EQUAL_DOT2);

        parseEnd();

    } else {
        // while
        f.isWhile = true;
    }

    // Body statements
    state.skip(EToken.LBRACE);

    while(state.etoken() != EToken.RBRACE) {
        parseStatementAtFunctionScope(f, state);
    }

    state.skip(EToken.RBRACE);
}
