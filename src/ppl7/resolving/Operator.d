module ppl7.resolving.Operator;

import ppl7.all;

enum Operator {
    // Arithmetic operators
    ADD,            // +
    SUB,            // -
    MUL,            // *
    DIV,            // /
    UDIV,           // udiv
    MOD,            // %
    UMOD,           // umod
    BIT_XOR,        // ^
    BIT_AND,        // &
    BIT_OR,         // |
    SHL,            // <<
    SHR,            // >>
    USHR,           // <<<

    // Assignment operators
    ASSIGN,         // =
    ADD_ASSIGN,     // +=
    SUB_ASSIGN,     // -=
    MUL_ASSIGN,     // *=
    DIV_ASSIGN,     // /=
    UDIV_ASSIGN,    // udiv=
    MOD_ASSIGN,     // %=
    UMOD_ASSIGN,    // umod=
    BIT_XOR_ASSIGN, // ^=
    BIT_AND_ASSIGN, // &=
    BIT_OR_ASSIGN,  // |=
    SHL_ASSIGN,     // shl=
    SHR_ASSIGN,     // shr=
    USHR_ASSIGN,    // ushr=

    // Boolean operators
    EQUAL,          // ==   these are only used internally by the compiler
    NOT_EQUAL,      // !=   these are only used internally by the compiler
    LT,             // <
    GT,             // >
    LTE,            // <=
    GTE,            // >=
    BOOL_AND,       // and
    BOOL_OR,        // or

    ULT,            // <<
    UGT,            // >>
    ULTE,           // <<=
    UGTE,           // >>=

    // Unary operators
    BOOL_NOT,       // not
    BIT_NOT,        // ~
    NEG,            // -
}

string stringOf(Operator op) {
    final switch(op) {
        case Operator.ADD: return "+";
        case Operator.SUB: return "-";
        case Operator.MUL: return "*";
        case Operator.DIV: return "/";
        case Operator.UDIV: return "udiv";
        case Operator.MOD: return "%";
        case Operator.UMOD: return "umod";
        case Operator.BIT_XOR: return "^";
        case Operator.BIT_AND: return "&";
        case Operator.BIT_OR: return "|";
        case Operator.BIT_NOT: return "~";
        case Operator.SHL: return "<<";
        case Operator.SHR: return ">>";
        case Operator.USHR: return "ushr";

        case Operator.ASSIGN: return "=";
        case Operator.ADD_ASSIGN: return "+=";
        case Operator.SUB_ASSIGN: return "-=";
        case Operator.MUL_ASSIGN: return "*=";
        case Operator.DIV_ASSIGN: return "/=";
        case Operator.UDIV_ASSIGN: return "udiv=";
        case Operator.MOD_ASSIGN: return "%=";
        case Operator.UMOD_ASSIGN: return "umod=";
        case Operator.BIT_XOR_ASSIGN: return "^=";
        case Operator.BIT_AND_ASSIGN: return "&=";
        case Operator.BIT_OR_ASSIGN: return "|=";

        case Operator.SHL_ASSIGN: return "<<=";
        case Operator.SHR_ASSIGN: return ">>=";
        case Operator.USHR_ASSIGN: return "ushr=";

        case Operator.EQUAL: return "==";
        case Operator.NOT_EQUAL: return "!=";

        case Operator.LT: return "<";
        case Operator.GT: return ">";
        case Operator.LTE: return "<=";
        case Operator.GTE: return ">=";

        case Operator.ULT: return "ult";
        case Operator.UGT: return "ugt";
        case Operator.ULTE: return "ulte";
        case Operator.UGTE: return "ugte";

        case Operator.BOOL_AND: return "and";
        case Operator.BOOL_OR: return "or";
        case Operator.BOOL_NOT: return "not";

        case Operator.NEG: return "-";
    }
    assert(false);
}

Operator toOperator(EToken tk) {
    switch(tk) {
        case EToken.EQUAL: return Operator.ASSIGN;
        case EToken.PLUS: return Operator.ADD;
        case EToken.MINUS: return Operator.SUB;
        case EToken.STAR: return Operator.MUL;
        case EToken.SLASH: return Operator.DIV;
        case EToken.PERCENT: return Operator.MOD;
        case EToken.HAT: return Operator.BIT_XOR;
        case EToken.AMPERSAND: return Operator.BIT_AND;
        case EToken.PIPE: return Operator.BIT_OR;
        case EToken.TILDE: return Operator.BIT_NOT;

        case EToken.LANGLE2: return Operator.SHL;
        case EToken.RANGLE2: return Operator.SHR;

        case EToken.EQUAL2: return Operator.EQUAL;
        case EToken.BANG_EQUAL: return Operator.NOT_EQUAL;
        case EToken.LANGLE: return Operator.LT;
        case EToken.RANGLE: return Operator.GT;
        case EToken.LANGLE_EQUAL: return Operator.LTE;
        case EToken.RANGLE_EQUAL: return Operator.GTE;

        case EToken.PLUS_EQUAL: return Operator.ADD_ASSIGN;
        case EToken.MINUS_EQUAL: return Operator.SUB_ASSIGN;
        case EToken.STAR_EQUAL: return Operator.MUL_ASSIGN;
        case EToken.SLASH_EQUAL: return Operator.DIV_ASSIGN;
        case EToken.PERCENT_EQUAL: return Operator.MOD_ASSIGN;
        case EToken.HAT_EQUAL: return Operator.BIT_XOR_ASSIGN;
        case EToken.AMPERSAND_EQUAL: return Operator.BIT_AND_ASSIGN;
        case EToken.PIPE_EQUAL: return Operator.BIT_OR_ASSIGN;

        case EToken.LANGLE2_EQUAL: return Operator.SHL_ASSIGN;
        case EToken.RANGLE2_EQUAL: return Operator.SHR_ASSIGN;

        // Handled elsewhere:
        // and, or
        // ushr, udiv, umod, ugt, ult, ugte, ulte
        // ushr=, udiv=, umod=

        default:
            throwIf(true, "Implement toOperator(%s)", tk);
    }
    assert(false);
}

enum Precedence : int {
    HIGHEST     = 0,
    CALL        = 2,
    DOT         = 2,
    INDEX       = 2,
    ADDRESS_OF  = 3,
    VALUE_OF    = 3,
    AS          = 3,
    UNARY       = 5,
    MUL         = 6,
    ADD         = 7,
    EQUAL       = 9,
    IS          = 9,
    BOOL_AND    = 11,
    ASSIGN      = 14,
    LOWEST      = 15
}

int precedenceOf(Operator op) {
    final switch(op) {
        case Operator.NEG: return 5;
        case Operator.BIT_NOT: return 5;
        case Operator.BOOL_NOT: return 5;

        case Operator.MUL: return 6;
        case Operator.DIV: return 6;
        case Operator.UDIV: return 6;
        case Operator.MOD: return 6;
        case Operator.UMOD: return 6;

        case Operator.ADD: return 7;
        case Operator.SUB: return 7;
        case Operator.BIT_XOR: return 7;
        case Operator.BIT_AND: return 7;
        case Operator.BIT_OR: return 7;
        case Operator.SHL: return 7;
        case Operator.SHR: return 7;
        case Operator.USHR: return 7;

        case Operator.EQUAL: return 9;
        case Operator.NOT_EQUAL: return 9;
        case Operator.LT: return 9;
        case Operator.GT: return 9;
        case Operator.LTE: return 9;
        case Operator.GTE: return 9;
        case Operator.ULT: return 9;
        case Operator.UGT: return 9;
        case Operator.ULTE: return 9;
        case Operator.UGTE: return 9;

        case Operator.BOOL_AND: return 11;
        case Operator.BOOL_OR: return 11;

        case Operator.ASSIGN: return 14;
        case Operator.ADD_ASSIGN: return 14;
        case Operator.SUB_ASSIGN: return 14;
        case Operator.MUL_ASSIGN: return 14;
        case Operator.DIV_ASSIGN: return 14;
        case Operator.UDIV_ASSIGN: return 14;
        case Operator.MOD_ASSIGN: return 14;
        case Operator.UMOD_ASSIGN: return 14;
        case Operator.BIT_XOR_ASSIGN: return 14;
        case Operator.BIT_AND_ASSIGN: return 14;
        case Operator.BIT_OR_ASSIGN: return 14;
        case Operator.SHL_ASSIGN: return 14;
        case Operator.SHR_ASSIGN: return 14;
        case Operator.USHR_ASSIGN: return 14;

        // Number, Identifier, Null = 15
    }
    assert(false);
}

bool isBool(Operator op) {
    switch(op) {
        case Operator.EQUAL:
        case Operator.NOT_EQUAL:
        case Operator.LT:
        case Operator.GT:
        case Operator.LTE:
        case Operator.GTE:
        case Operator.ULT:
        case Operator.UGT:
        case Operator.ULTE:
        case Operator.UGTE:
        case Operator.BOOL_AND:
        case Operator.BOOL_OR:
            return true;
        default:
            return false;
    }
}

bool isUnary(Operator op) {
    switch(op) {
        case Operator.NEG:
        case Operator.BIT_NOT:
        case Operator.BOOL_NOT:
            return true;
        default:
            return false;
    }
}

bool isAssign(Operator op) {
    switch(op) {
        case Operator.ASSIGN:
        case Operator.ADD_ASSIGN:
        case Operator.SUB_ASSIGN:
        case Operator.MUL_ASSIGN:
        case Operator.DIV_ASSIGN:
        case Operator.MOD_ASSIGN:
        case Operator.BIT_XOR_ASSIGN:
        case Operator.BIT_AND_ASSIGN:
        case Operator.BIT_OR_ASSIGN:
        case Operator.SHL_ASSIGN:
        case Operator.SHR_ASSIGN:
        case Operator.USHR_ASSIGN:
        case Operator.UDIV_ASSIGN:
        case Operator.UMOD_ASSIGN:
            return true;
        default:
            return false;
    }
}

bool isUnsigned(Operator op) {
    switch(op) {
        case Operator.ULT:
        case Operator.UGT:
        case Operator.ULTE:
        case Operator.UGTE:
        case Operator.UDIV:
        case Operator.UDIV_ASSIGN:
        case Operator.UMOD:
        case Operator.UMOD_ASSIGN:
        case Operator.USHR:
        case Operator.USHR_ASSIGN:
            return true;
        default:
            return false;
    }
}
