module ppl7.tokenising.EToken;

import ppl7.all;

enum EToken {
    NONE,
    IDENTIFIER,
    NUMBER,
    STRING,

    PLUS,               // +
    MINUS,              // -
    STAR,               // *
    SLASH,              // /
    SLASH2,             // //
    PERCENT,            // %
    PERCENT2,           // %%
    HAT,                // ^
    AMPERSAND,          // &
    PIPE,               // |
    TILDE,              // ~
    LANGLE2,            // <<
    RANGLE2,            // >>
    RANGLE3,            // >>>

    EQUAL,              // =

    PLUS_EQUAL,         // +=
    MINUS_EQUAL,        // -=
    STAR_EQUAL,         // *=
    SLASH_EQUAL,        // /=
    SLASH2_EQUAL,       // //=
    PERCENT_EQUAL,      // %=
    PERCENT2_EQUAL,     // %%=
    HAT_EQUAL,          // ^=
    AMPERSAND_EQUAL,    // &=
    PIPE_EQUAL,         // |=
    LANGLE2_EQUAL,      // <<=
    RANGLE2_EQUAL,      // >>=
    RANGLE3_EQUAL,      // >>>=

    LANGLE_EQUAL,       // <=
    RANGLE_EQUAL,       // >=
    EQUAL2,             // ==
    BANG_EQUAL,         // !=

    ULT,                // |<|
    UGT,                // |>|
    ULTE,               // |<=|
    UGTE,               // |>=|

    LANGLE,             // <
    RANGLE,             // >
    LPAREN,             // (
    RPAREN,             // )
    LBRACE,             // {
    RBRACE,             // }
    LSQUARE,            // [
    LSQUARE2,           // [[
    RSQUARE,            // ]
    RSQUARE2,           // ]]

    BANG,               // !
    RARROW,             // ->

    DOT,                // .
    COMMA,              // ,
    COLON,              // :
    COLON2,             // ::
    SEMICOLON,          // ;

    ELLIPSIS,           // ...

    QUESTION,           // ?
    AT,                 // @
    DOLLAR,             // $
}
int lengthOf(EToken t) {
    final switch(t) with(EToken) {
        case NONE:
        case IDENTIFIER:
        case NUMBER:
        case STRING:
            return 0;
        case PLUS:
        case MINUS:
        case STAR:
        case SLASH:
        case PERCENT:
        case HAT:
        case AMPERSAND:
        case PIPE:
        case TILDE:
        case EQUAL:
        case LANGLE:
        case RANGLE:
        case LPAREN:
        case RPAREN:
        case LBRACE:
        case RBRACE:
        case LSQUARE:
        case RSQUARE:
        case DOT:
        case COMMA:
        case COLON:
        case SEMICOLON:
        case BANG:
        case QUESTION:
        case AT:
        case DOLLAR:
            return 1;
        case PLUS_EQUAL:
        case MINUS_EQUAL:
        case STAR_EQUAL:
        case SLASH_EQUAL:
        case PERCENT_EQUAL:
        case HAT_EQUAL:
        case AMPERSAND_EQUAL:
        case PIPE_EQUAL:
        case LANGLE_EQUAL:
        case RANGLE_EQUAL:
        case EQUAL2:
        case BANG_EQUAL:
        case LANGLE2:
        case RANGLE2:
        case RARROW:
        case COLON2:
        case LSQUARE2:
        case RSQUARE2:
        case SLASH2:
        case PERCENT2:
            return 2;
        case SLASH2_EQUAL:
        case PERCENT2_EQUAL:
        case LANGLE2_EQUAL:
        case RANGLE2_EQUAL:
        case RANGLE3:
        case ELLIPSIS:
        case ULT:
        case UGT:
            return 3;
        case RANGLE3_EQUAL:
        case ULTE:
        case UGTE:
            return 4;
    }
}
string stringOf(EToken t) {
    final switch(t) with(EToken) {
        case NONE:
        case IDENTIFIER:
        case NUMBER:
        case STRING:
            return "";
        case PLUS: return "+";
        case MINUS: return "-";
        case STAR: return "*";
        case SLASH: return "/";
        case SLASH2: return "//";
        case PERCENT: return "%";
        case PERCENT2: return "%%";
        case HAT: return "^";
        case AMPERSAND: return "&";
        case PIPE: return "|";
        case TILDE: return "~";
        case LANGLE2: return "<<";
        case RANGLE2: return ">>";
        case RANGLE3: return ">>>";
        case PLUS_EQUAL: return "+=";
        case MINUS_EQUAL: return "-=";
        case STAR_EQUAL: return "*=";
        case SLASH_EQUAL: return "/=";
        case SLASH2_EQUAL: return "//=";
        case PERCENT_EQUAL: return "%=";
        case PERCENT2_EQUAL: return "%%=";
        case HAT_EQUAL: return "^=";
        case AMPERSAND_EQUAL: return "&=";
        case PIPE_EQUAL:  return "|=";
        case LANGLE2_EQUAL: return "<<=";
        case RANGLE2_EQUAL: return ">>=";
        case RANGLE3_EQUAL: return ">>>=";
        case EQUAL: return "=";
        case LANGLE: return "<";
        case RANGLE: return ">";
        case LANGLE_EQUAL: return "<=";
        case RANGLE_EQUAL: return ">=";
        case EQUAL2: return "==";
        case BANG_EQUAL: return "!=";
        case LPAREN: return "(";
        case RPAREN: return ")";
        case LBRACE: return "{";
        case RBRACE: return "}";
        case LSQUARE: return "[";
        case LSQUARE2: return "[[";
        case RSQUARE: return "]";
        case RSQUARE2: return "]]";
        case RARROW: return "->";
        case DOT: return ".";
        case COMMA: return ",";
        case COLON: return ":";
        case SEMICOLON: return ";";
        case ELLIPSIS: return "...";
        case BANG: return "!";
        case COLON2: return "::";
        case QUESTION: return "?";
        case AT: return "@";
        case DOLLAR: return "$";
        case ULT: return "|<|";
        case UGT: return "|>|";
        case ULTE: return "|<=|";
        case UGTE: return "|>=|";
    }
}
