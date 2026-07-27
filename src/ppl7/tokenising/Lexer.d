module ppl7.tokenising.Lexer;

import ppl7.all;

final class Lexer {
public:
    this(Module mod, string source) {
        this.mod = mod;
        this.source = source;
    }
    Token[] tokenise() {

        updateLoggingContext(mod, LoggingStage.Tokenising);

        while(pos < source.length) {
            char ch = peek();
            //log("ch = %s", ch);

            if(ch < 33) {
                lexWhitespace();
            } else switch(ch) {
                case '"':
                    lexString();
                    break;
                case '\'':
                    lexChar();
                    break;
                case '/': {
                    if(peek(1)=='*') {
                        lexMultiLineComment();
                        break;
                    }
                    Match[] m = [
                        {EToken.SLASH2_EQUAL,   "//="},
                        {EToken.SLASH2,         "//"},
                        {EToken.SLASH_EQUAL,    "/="},
                        {EToken.SLASH,          "/"}
                    ];
                    matchFirst(m);
                    break;
                }
                case '#':
                    lexLineComment();
                    break;
                case '+': {
                    Match[] m = [
                        {EToken.PLUS_EQUAL,     "+="},
                        {EToken.PLUS,           "+"},
                    ];
                    matchFirst(m);
                    break;
                }
                case '-': {
                    if(tokenStart==pos && peek(1).isDigit()) {
                        // This is a negative number
                        pos++;
                        break;
                    }
                    Match[] m = [
                        {EToken.MINUS_EQUAL,     "-="},
                        {EToken.RARROW,          "->"},
                        {EToken.MINUS,           "-"},
                    ];
                    matchFirst(m);
                    break;
                }
                case '*': {
                    Match[] m = [
                        {EToken.STAR_EQUAL,     "*="},
                        {EToken.STAR,           "*"},
                    ];
                    matchFirst(m);
                    break;
                }
                case '%': {
                    Match[] m = [
                        {EToken.PERCENT2_EQUAL, "%%="},
                        {EToken.PERCENT2,       "%%"},
                        {EToken.PERCENT_EQUAL,  "%="},
                        {EToken.PERCENT,        "%"}
                    ];
                    matchFirst(m);
                    break;
                }
                case '^': {
                    Match[] m = [
                        {EToken.HAT_EQUAL,  "^="},
                        {EToken.HAT,        "^"}
                    ];
                    matchFirst(m);
                    break;
                }
                case '&': {
                    Match[] m = [
                        {EToken.AMPERSAND_EQUAL,  "&="},
                        {EToken.AMPERSAND,        "&"}
                    ];
                    matchFirst(m);
                    break;
                }
                case '|': {
                    Match[] m = [
                        {EToken.UGTE,       "|>=|"},
                        {EToken.ULTE,       "|<=|"},
                        {EToken.ULT,        "|<|"},
                        {EToken.UGT,        "|>|"},
                        {EToken.PIPE_EQUAL, "|="},
                        {EToken.PIPE,       "|"}
                    ];
                    matchFirst(m);
                    break;
                }
                case '~': addToken(EToken.TILDE); break;
                case '(': addToken(EToken.LPAREN); break;
                case ')': addToken(EToken.RPAREN); break;
                case '{': addToken(EToken.LBRACE); break;
                case '}': addToken(EToken.RBRACE); break;
                case '[': {
                    Match[] m = [
                        {EToken.LSQUARE2, "[["},
                        {EToken.LSQUARE,  "["}
                    ];
                    matchFirst(m);
                    break;
                }
                case ']': {
                    Match[] m = [
                        {EToken.RSQUARE2, "]]"},
                        {EToken.RSQUARE,  "]"},
                    ];
                    matchFirst(m);
                    break;
                }
                case ';': addToken(EToken.SEMICOLON); break;
                case ',': addToken(EToken.COMMA); break;
                case '?': addToken(EToken.QUESTION); break;
                case '@': addToken(EToken.AT); break;
                case '$': addToken(EToken.DOLLAR); break;

                case ':': {
                    Match[] m = [
                        {EToken.COLON2, "::"},
                        {EToken.COLON,  ":"}
                    ];
                    matchFirst(m);
                    break;
                }
                case '.': {
                    if(isDigit(peek(-1)) && isDigit(peek(1))) {
                        // Assume this is a real number
                        pos++;
                        break;
                    }
                    Match[] m = [
                        {EToken.ELLIPSIS,    "..."},
                        {EToken.DOT2_EQUAL,  "..="},
                        {EToken.DOT2_LANGLE, "..<"},
                        {EToken.DOT2,        ".."},
                        {EToken.DOT,         "."}
                    ];
                    matchFirst(m);
                    break;
                }
                case '!': {
                    Match[] m = [
                        {EToken.BANG_EQUAL, "!="},
                        {EToken.BANG,       "!"}
                    ];
                    matchFirst(m);
                    break;
                }
                case '=': {
                    Match[] m = [
                        {EToken.EQUAL_DOT2, "=.."},
                        {EToken.EQUAL2,     "=="},
                        {EToken.EQUAL,      "="}
                    ];
                    matchFirst(m);
                    break;
                }
                case '<': {
                    Match[] m = [
                        {EToken.LANGLE2_EQUAL,  "<<="},
                        {EToken.LANGLE2,        "<<"},
                        {EToken.LANGLE_EQUAL,   "<="},
                        {EToken.LANGLE,         "<"},
                    ];
                    matchFirst(m);
                    break;
                }
                case '>': {
                    Match[] m = [
                        {EToken.RANGLE3_EQUAL,  ">>>="},
                        {EToken.RANGLE3,        ">>>"},
                        {EToken.RANGLE2_EQUAL,  ">>="},
                        {EToken.RANGLE2,        ">>"},
                        {EToken.RANGLE_EQUAL,   ">="},
                        {EToken.RANGLE_DOT2,    ">.."},
                        {EToken.RANGLE,         ">"},
                    ];
                    matchFirst(m);
                    break;
                }

                default:
                    pos++;
                    break;
            }
        }
        addToken();

        return tokens;
    }
private:
    Module mod;
    string source;
    int pos;
    int line;
    int tokenStart;
    int lineStart;
    Token[] tokens;

    struct Match {
        EToken tk;
        string str;
    }

    void matchFirst(Match[] matches) {
        assert(matches.length > 0);

        bool isMatch(string s) {
            if(s.length < 2) return true;
            foreach(i; 1..s.length) {
                if(peek(i.as!int) != s[i]) return false;
            }
            return true;
        }

        foreach(m; matches) {
            if(isMatch(m.str)) {
                addToken(m.tk);
                return;
            }
        }
        assert(false, "Nothing matched");
    }

    char peek(int offset = 0) {
        return pos + offset < source.length ? source[pos + offset] : 0;
    }
    void addToken(EToken tk = EToken.NONE) {
        if(pos > tokenStart) {
            string text = source[tokenStart..pos];
            int column  = tokenStart - lineStart;

            // Identify the token type
            auto tk2 = EToken.IDENTIFIER;
            char ch1 = text[0];
            char ch2 = text.length > 1 ? text[1] : 0;
            if(ch1 == '\'') tk2 = EToken.NUMBER;
            else if(ch1 == '"') tk2 = EToken.STRING;
            else if(isDigit(ch1) || (ch1=='-' && isDigit(ch2)) || (ch1=='.' && isDigit(ch2))) tk2 = EToken.NUMBER;

            tokens ~= Token(tk2, text, line, column);
        }
        if(tk != EToken.NONE) {
            int len = lengthOf(tk);
            string text = source[pos..pos+len];
            int column  = pos - lineStart;

            tokens ~= Token(tk, text, line, column);
            pos += len;
        }
        // Reset the token start position
        tokenStart = pos;
    }
    bool isEol() {
        return peek().isOneOf(10, 13);
    }
    void eol() {
        // can be 13,10 or just 10
        if(peek()==13) pos++;
        if(peek()==10) pos++;
        line++;
        lineStart = pos;
    }
    /**
     *  "sdfsdfs\"df\nsdf"      string struct (*todo)
     *  "sdfsdfs\"df\nsdf"z     zero terminated byte*
     */
    void lexString() {
        addToken();
        assert(peek()=='"');
        pos++;
        while(pos < source.length) {
            if(peek()=='"') {
                break;
            } else if(peek()=='\\' && peek(1)=='"') {
                pos+=2;
            } else {
                pos++;
            }
        }
        assert(peek()=='"');
        pos++;

        if(peek()=='z') {
            pos++;
        }
        addToken();
    }
    /**
     *  's' | '\n' | '\\'
     */
    void lexChar() {
        addToken();
        assert(peek()=='\'');

        if(peek(1)=='\'') {
            syntaxError(mod, line, pos - lineStart, "Empty character literal");
        }

        pos++;
        if(peek()=='\\') {
            pos+=2;
        } else {
            pos++;
        }
        assert(peek()=='\'');
        pos++;
        addToken();
    }
    void lexWhitespace() {
        addToken();
        while(pos < source.length) {
            if(isEol()) {
                eol();
            } else if(peek() < 33) {
                pos++;
            } else {
                break;
            }
        }
        tokenStart = pos;
    }
    void lexLineComment() {
        if(peek() == '/') writefln("legacy line comment in file %s at line %s", mod.relFilename, line+1);
        addToken();
        while(pos < source.length) {
            if(isEol()) {
                eol();
                break;
            }
            pos++;
        }
        tokenStart = pos;
    }
    void lexMultiLineComment() {
        addToken();
        while(pos < source.length) {
            if(isEol()) {
                eol();
            } else if(peek()=='*' && peek(1)=='/') {
                pos+=2;
                break;
            } else {
                pos++;
            }
        }
        tokenStart = pos;
    }
}
