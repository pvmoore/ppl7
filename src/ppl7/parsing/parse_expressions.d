module ppl7.parsing.parse_expressions;

import ppl7.all;

/**
 * Parse an expression
 */
void parseExpression(Node parent, ParseState state) {
    parseSingle(parent, state);
    parseInfix(parent, state);
}

/**
 * Parse an expression. This overload ensures that any new Expressions do not get reordered above the current parent.
 */
void parseExpressionWithUpperBound(Node parent, ParseState state) {

    auto p = makeNode!Parens(state);

    parseSingle(p, state);
    parseInfix(p, state);

    assert(p.numChildren() == 1);
    parent.add(p.first());
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

/**
 * Parse an Expression left hand side.
 *
 *   - AddressOf
 *   - ArrayLiteral
 *   - Builtin
 *   - Call
 *   - Identifier
 *   - If
 *   - ModuleRef
 *   - Null
 *   - Number
 *   - Parens
 *   - StringLiteral
 *   - StructLiteral
 *   - Type
 *   - Unary
 *   - ValueOf
 */
void parseSingle(Node parent, ParseState state) {

    if(isType(state)) {
        parseType(parent, state);
        return;
    }

    switch(state.etoken()) {
        case EToken.IDENTIFIER:
            if("if" == state.text()) {
                parseIf(parent, state);
                return;
            }
            if("null" == state.text()) {
                parseNull(parent, state);
                return;
            }
            if("true" == state.text() || "false" == state.text()) {
                parseNumber(parent, state);
                return;
            }
            if("not" == state.text()) {
                syntaxError(state, "Boolean 'not' should be replaced with 'is false'");
                return;
            }
            // Function call
            if(state.peek(1).etoken == EToken.LPAREN) {
                parseCall(parent, state);
                return;
            }
            // Module alias
            if(state.mod.isModuleAlias(state.text())) {
                parseModuleRef(parent, state);
                return;
            }
            // Local variable
            parseIdentifier(parent, state);
            return;
        case EToken.NUMBER:
            parseNumber(parent, state);
            return;
        case EToken.TILDE:
        case EToken.MINUS:
            parseUnary(parent, state);
            return;
        case EToken.LPAREN:
            parseParens(parent, state);
            return;
        case EToken.STRING:
            parseStringLiteral(parent, state);
            return;
        case EToken.LSQUARE:
            parseArrayLiteral(parent, state);
            return;
        case EToken.AMPERSAND:
            parseAddressOf(parent, state);
            return;
        case EToken.STAR:
            parseValueOf(parent, state);
            return;
        case EToken.BANG:
            syntaxError(state, "Use 'not' instead of '!' for boolean negation");
            return;
        case EToken.AT:
        case EToken.COLON2:
            parseBuiltin(parent, state);
            return;
        case EToken.LBRACE:
            parseStructLiteral(parent, state);
            return;
        default:
            break;
    }
    syntaxError(state, "Expecting expression but found %s".format(state.token()));
}

/**
 * Optional Expression infix / middle:
 *  - Binary
 *  - As
 *  - Is
 *  - Index
 *  - Dot
 */
void parseInfix(Node parent, ParseState state) {
    while(!state.eof()) {

        switch(state.etoken()) {
            case EToken.NONE:
            case EToken.LBRACE:
            case EToken.RBRACE:
            case EToken.LPAREN:
            case EToken.RPAREN:
            case EToken.RSQUARE:
            case EToken.SEMICOLON:
            case EToken.COMMA:
            case EToken.NUMBER:
            case EToken.STRING:
            case EToken.QUESTION:
            case EToken.AT:
            case EToken.DOLLAR:
            case EToken.COLON2:
            case EToken.LSQUARE2:
            case EToken.DOT2:
            case EToken.RANGLE_DOT2:
            case EToken.EQUAL_DOT2:
            case EToken.DOT2_EQUAL:
            case EToken.DOT2_LANGLE:
                return;
            case EToken.IDENTIFIER:
                switch(state.text()) {
                    case "is": {
                        auto i = parseAndReturnIs(state);
                        parent = attachAndRead(parent, i, state, true);
                        break;
                    }
                    case "as": {
                        auto a = parseAndReturnAs(state);
                        parent = attachAndRead(parent, a, state, true);
                        break;
                    }
                    case "and":
                    case "or": {
                        auto b = parseAndReturnBinary(state);
                        parent = attachAndRead(parent, b, state, true);
                        break;
                    }
                    default:
                        return;
                }
                break;
            case EToken.EQUAL2:
                syntaxError(state, "Use 'is' for equality comparison");
                return;
            case EToken.BANG_EQUAL:
                syntaxError(state, "Use 'is not' for inequality comparison");
                return;

            case EToken.PLUS:
            case EToken.MINUS:
            case EToken.STAR:
            case EToken.SLASH:
            case EToken.SLASH2:
            case EToken.PERCENT:
            case EToken.PERCENT2:
            case EToken.HAT:
            case EToken.AMPERSAND:
            case EToken.PIPE:

            case EToken.UGTE:
            case EToken.UGT:
            case EToken.ULTE:
            case EToken.ULT:

            case EToken.EQUAL:
            case EToken.LANGLE:
            case EToken.RANGLE:
            case EToken.LANGLE_EQUAL:
            case EToken.RANGLE_EQUAL:
            case EToken.LANGLE2:
            case EToken.RANGLE2:
            case EToken.RANGLE3:
            case EToken.LANGLE2_EQUAL:
            case EToken.RANGLE2_EQUAL:
            case EToken.RANGLE3_EQUAL:

            case EToken.PLUS_EQUAL:
            case EToken.MINUS_EQUAL:
            case EToken.STAR_EQUAL:
            case EToken.SLASH_EQUAL:
            case EToken.SLASH2_EQUAL:
            case EToken.PERCENT_EQUAL:
            case EToken.PERCENT2_EQUAL:
            case EToken.HAT_EQUAL:
            case EToken.AMPERSAND_EQUAL:
            case EToken.PIPE_EQUAL:
                // exit if this token is on the next line
                if(!state.isOnSameLine()) return;

                auto b = parseAndReturnBinary(state);
                parent = attachAndRead(parent, b, state, true);
                break;
            case EToken.LSQUARE: {
                auto i = parseAndReturnIndex(state);
                parent = attachAndRead(parent, i, state, false);
                break;
            }
            case EToken.DOT: {
                auto d = parseAndReturnDot(state);
                parent = attachAndRead(parent, d, state, true);
                break;
            }
            default: throwIf(true, "Unhandled infix %s", state.token());
        }
    }
}

Expression attachAndRead(Node parent, Expression newExpr, ParseState state, bool andRead) {

    Node prev = parent;

    // Check for ambiguous boolean and/or expressions
    if(Binary b = newExpr.as!Binary) {
        if(b.op == Operator.BOOL_AND || b.op == Operator.BOOL_OR) {
            if(Binary b2 = parent.as!Binary) {
                if((b2.op == Operator.BOOL_AND || b2.op == Operator.BOOL_OR) && b2.op != b.op) {
                    syntaxError(state, -1, "Use parentheses to clarify the intended meaning of this boolean expression");
                }
            }
        }
    }

    // Swap expressions according to operator precedence
    if(Expression prevExpr = prev.as!Expression) {

        // Adjust to account for operator precedence
        while(prevExpr.parent && newExpr.precedence() >= prevExpr.precedence()) {

            if(!prevExpr.parent.isA!Expression) {
                prev = prevExpr.parent;
                break;
            }

            prevExpr = prevExpr.parent.as!Expression;
            prev     = prevExpr;
        }
    }

    newExpr.add(prev.last());

    prev.add(newExpr);

    if(andRead) {
        parseSingle(newExpr, state);
    }

    return newExpr;
}

/**
 * '&' Expression
 */
void parseAddressOf(Node parent, ParseState state) {
    auto a = makeNode!AddressOf(state);
    parent.add(a);

    state.skip(EToken.AMPERSAND);

    parseExpression(a, state);
}

/**
 * '[' { Expression [ ',' ] } ']'
 */
void parseArrayLiteral(Node parent, ParseState state) {
    ArrayLiteral a = makeNode!ArrayLiteral(state);
    parent.add(a);

    state.skip(EToken.LSQUARE);

    while(state.etoken() != EToken.RSQUARE) {
        parseExpression(a, state);

        // ,
        if(state.etoken() == EToken.COMMA) {
            state.skip(EToken.COMMA);
        }
    }

    state.skip(EToken.RSQUARE);
}

/**
 * '@' name '(' Expression ')'
 */
void parseBuiltin(Node parent, ParseState state) {
    auto b = makeNode!Builtin(state);
    parent.add(b);

    state.skip(EToken.AT);

    b.name = "@" ~ state.text();
    state.next();

    switch(b.name) {
        case "@isArray":
        case "@isBool":
        case "@isConst":
        case "@isEnum":
        case "@isFunction":
        case "@isImmutable":
        case "@isInteger":
        case "@isPacked":
        case "@isPointer":
        case "@isPublic":
        case "@isReal":
        case "@isStruct":
        case "@isUnion":
        case "@isValue":
        case "@isVoid":

        case "@alignOf":
        case "@offsetOf":
        case "@sizeOf":
        case "@initOf":

        case "@debug":
            // These must have 1 argument
            state.skip(EToken.LPAREN);
            parseExpressionWithUpperBound(b, state);
            state.skip(EToken.RPAREN, "Too many arguments provided?");
            break;

        case "@ushr":
        case "@shr":
        case "@shl":
            // These must have 2 arguments
            state.skip(EToken.LPAREN);

            parseExpressionWithUpperBound(b, state);
            state.skip(EToken.COMMA);
            parseExpressionWithUpperBound(b, state);

            state.skip(EToken.RPAREN, "Did you provide too many arguments?");
            break;

        case "@property":
            // This must have 2 or 3 arguments

            state.skip(EToken.LPAREN);

            //Type
            parseExpressionWithUpperBound(b, state);

            // Name
            state.skip(EToken.COMMA);
            parseExpressionWithUpperBound(b, state);

            // Optional default value
            if(state.etoken() == EToken.COMMA) {
                state.skip(EToken.COMMA);
                parseExpressionWithUpperBound(b, state);
            }

            state.skip(EToken.RPAREN, "Did you provide too many arguments?");
            break;
        default:
            syntaxError(state, "Unknown builtin function %s".format(b.name));
    }
}

/**
 * name '(' { Expression } ')'
 */
void parseCall(Node parent, ParseState state) {
    Call c = makeNode!Call(state);
    c.target.call = c;
    parent.add(c);

    c.name = state.text(); state.next();

    // Arguments
    state.skip(EToken.LPAREN);

    while(state.etoken() != EToken.RPAREN) {
        parseExpressionWithUpperBound(c, state);

        // ,
        if(state.etoken() == EToken.COMMA) {
            state.skip(EToken.COMMA);
        }
    }

    state.skip(EToken.RPAREN);
}

/**
 * name
 */
void parseIdentifier(Node parent, ParseState state) {
    Identifier i = makeNode!Identifier(state);
    i.target.identifier = i;
    i.name = state.text();
    parent.add(i);

    state.next();
}

/**
 * if        ::= 'if' condition then [ else ]
 * condition ::= '(' Expression ')'
 * then      ::= [ '{ ] { Statement } [ '}' ]
 * else      ::= 'else' [ '{' ] { Statement } [ '}' ]
 */
void parseIf(Node parent, ParseState state) {
    If i = makeNode!If(state);
    parent.add(i);

    state.skip("if");

    // Condition
    state.skip(EToken.LPAREN);
    parseExpression(i, state);
    state.skip(EToken.RPAREN);

    // 'then' branch (required)
    if(state.etoken() == EToken.LBRACE) {
        // Statement block
        state.skip(EToken.LBRACE);

        while(state.etoken() != EToken.RBRACE) {
            parseStatementAtFunctionScope(i, state);
        }

        state.skip(EToken.RBRACE);
    } else {
        // Single then Statement
        parseStatementAtFunctionScope(i, state);
    }

    i.numThenStatements = i.numChildren() - 1;

    // 'else' branch (optional)
    if("else" == state.text()) {
        i.hasElse = true;
        state.skip("else");

        if(state.etoken() == EToken.LBRACE) {
            // Statement block
            state.skip(EToken.LBRACE);

            while(state.etoken() != EToken.RBRACE) {
                parseStatementAtFunctionScope(i, state);
            }
            state.skip(EToken.RBRACE);
        } else {
            // Single else Statement
            parseStatementAtFunctionScope(i, state);
        }
    }
}

/**
 * moduleAlias
 */
void parseModuleRef(Node parent, ParseState state) {
    ModuleRef m = makeNode!ModuleRef(state);
    parent.add(m);

    m.mod = state.mod.importedModulesQualified[state.text()];
    state.next();
}

/**
 * 123
 * 123.4
 */
void parseNumber(Node parent, ParseState state) {
    Number n = makeNode!Number(state);
    n.stringValue = state.text(); state.next();

    parent.add(n);
}

/**
 * null
 */
void parseNull(Node parent, ParseState state) {
    Null n = makeNode!Null(state);
    parent.add(n);

    state.next();
}

/**
 * '(' Expression ')'
 */
void parseParens(Node parent, ParseState state) {
    Parens p = makeNode!Parens(state);
    parent.add(p);

    state.skip(EToken.LPAREN);

    // todo - handle empty or double parens
    //if(state.kind()==EToken.LPAREN) errorBadSyntax(module_, t, "Empty parenthesis");

    parseExpression(p, state);

    state.skip(EToken.RPAREN);
}

/**
 * "string"
 * "string" "string"
 * "string"z
 */
void parseStringLiteral(Node parent, ParseState state) {
    StringLiteral s = makeNode!StringLiteral(state);
    parent.add(s);

    string value = state.text(); state.next();

    if(value.endsWith("z")) {
        value = value[1..$-2];
        s.isCString = true;
    } else {

        value = value[1..$-1];

        // This is a string struct string literal.
        // Consume multiple string literals as long as they are not c-strings
        while(state.etoken() == EToken.STRING) {
            if(state.text().endsWith("z")) break;

            // Append the string literal
            value ~= state.text()[1..$-1];
            state.next();
        }
    }

    s.stringValue = value;
}

/**
 * '{' { [name ':'] Expression } [',' Expression ] '}'
 */
void parseStructLiteral(Node parent, ParseState state) {
    StructLiteral s = makeNode!StructLiteral(state);
    parent.add(s);

    state.skip(EToken.LBRACE);

    while(state.etoken() != EToken.RBRACE) {

        // Named argument:
        if(state.etoken() == EToken.IDENTIFIER && state.peek(1).etoken == EToken.COLON) {
            s.names ~= state.text(); state.next();
            state.skip(EToken.COLON);
        } else {
            s.names ~= null;
        }

        parseExpressionWithUpperBound(s, state);

        // ,
        if(state.etoken() == EToken.COMMA) {
            state.skip(EToken.COMMA);
        }
    }

    state.skip(EToken.RBRACE);
}

/**
 * not | ~ | -
 */
void parseUnary(Node parent, ParseState state) {

    auto u = makeNode!Unary(state);
    parent.add(u);

    /// - ~
    if(state.etoken()==EToken.TILDE) {
        u.op = Operator.BIT_NOT;
    } else if(state.etoken()==EToken.MINUS) {
        u.op = Operator.NEG;
    } else assert(false, "How did we get here?");

    state.next();

    // Parse the expression
    parseExpression(u, state);
}

/**
 * '*' Expression
 */
void parseValueOf(Node parent, ParseState state) {
    auto v = makeNode!ValueOf(state);
    parent.add(v);

    state.skip(EToken.STAR);

    parseExpression(v, state);
}

/**
 * 'as' Type
 */
Expression parseAndReturnAs(ParseState state) {

    auto a = makeNode!As(state);

    state.skip("as");

    return a;
}

/**
 * 'is' [ 'not' ] Type
 */
Expression parseAndReturnIs(ParseState state) {

    auto a = makeNode!Is(state);

    state.skip("is");

    if("not" == state.text()) {
        a.negate = true;
        state.next();
    }

    return a;
}

/**
 * + - * / % ^ & | etc...
 */
Binary parseAndReturnBinary(ParseState state) {
    Binary b = makeNode!Binary(state);
    string text = state.text();

    switch(text) {
        case "and": b.op = Operator.BOOL_AND; break;
        case "or": b.op = Operator.BOOL_OR; break;
        default: b.op = toOperator(state.etoken()); break;
    }

    state.next();
    return b;
}

/**
 * '[' Expression ']'
 */
Index parseAndReturnIndex(ParseState state) {
    Index i = makeNode!Index(state);
    state.skip(EToken.LSQUARE);

    parseExpression(i, state);

    state.skip(EToken.RSQUARE);
    return i;
}

/**
 * '.'
 */
Dot parseAndReturnDot(ParseState state) {
    Dot d = makeNode!Dot(state);
    state.skip(EToken.DOT);

    return d;
}
