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
                case '/':
                    if(peek(1)=='/') {
                        lexLineComment();
                    } else if(peek(1)=='*') {
                        lexMultiLineComment();
                    } else if(peek(1)=='=') {
                        addToken(EToken.SLASH_EQUAL);
                    } else {
                        addToken(EToken.SLASH);
                    }
                    break;
                case '+': 
                    if(peek(1) == '=') {
                        addToken(EToken.PLUS_EQUAL);
                    } else {
                        addToken(EToken.PLUS);
                    } 
                    break;
                case '-': 
                    if(tokenStart==pos && peek(1).isDigit()) {
                        // This is a negative number
                        pos++;
                        break;
                    }
                    if(peek(1) == '=') {
                        addToken(EToken.MINUS_EQUAL);
                    } else if(peek(1) == '>') {
                        addToken(EToken.RARROW); 
                    } else {
                        addToken(EToken.MINUS);
                    }                    
                    break;
                case '*': 
                    if(peek(1) == '=') {
                        addToken(EToken.STAR_EQUAL);
                    } else {
                        addToken(EToken.STAR);
                    }
                    break;
                case '%': 
                    if(peek(1) == '=') {
                        addToken(EToken.PERCENT_EQUAL);
                    } else {
                        addToken(EToken.PERCENT);
                    } 
                    break;
                case '^': 
                    if(peek(1) == '=') {
                        addToken(EToken.HAT_EQUAL);
                    } else {
                        addToken(EToken.HAT);
                    }
                    break;
                case '&': 
                    if(peek(1) == '=') {
                        addToken(EToken.AMPERSAND_EQUAL);
                    } else {
                        addToken(EToken.AMPERSAND);
                    }
                    break;
                case '|': 
                    if(peek(1) == '=') {
                        addToken(EToken.PIPE_EQUAL);
                    } else {
                        addToken(EToken.PIPE);
                    }
                    break;
                case '~': 
                    if(peek(1) == '=') {
                        addToken(EToken.TILDE_EQUAL);
                    } else {
                        addToken(EToken.TILDE);
                    }
                    break;

                case '(': addToken(EToken.LPAREN); break;
                case ')': addToken(EToken.RPAREN); break;
                case '{': addToken(EToken.LBRACE); break;
                case '}': addToken(EToken.RBRACE); break;
                case '[': addToken(EToken.LSQUARE); break;
                case ']': addToken(EToken.RSQUARE); break;

                case ';': addToken(EToken.SEMICOLON); break;
                case ',': addToken(EToken.COMMA); break;
                case '?': addToken(EToken.QUESTION); break;
                //case '@': addToken(EToken.AT); break;
                case '#': addToken(EToken.HASH); break;
                case '$': addToken(EToken.DOLLAR); break;

                case ':': 
                    if(peek(1)==':') {
                        addToken(EToken.COLON2);
                    } else {
                        addToken(EToken.COLON); 
                    }
                    break;
                case '.': 
                    if(isDigit(peek(-1)) && isDigit(peek(1))) {
                        // Assume this is a real number
                        pos++;
                    } else if(peek(1)=='.' && peek(2)=='.') {
                        addToken(EToken.ELLIPSIS);
                    } else {
                        addToken(EToken.DOT); 
                    }
                    break;

                case '!': 
                    if(peek(1)=='=') {
                        addToken(EToken.BANG_EQUAL);
                    } else {
                        addToken(EToken.BANG);
                    } 
                    break;
                case '=': 
                    if(peek(1)=='=') {
                        addToken(EToken.EQUAL2);
                    } else {
                        addToken(EToken.EQUAL);
                    } 
                    break;
                case '<': 
                    if(peek(1)=='=') {
                        addToken(EToken.LANGLE_EQUAL);
                    } else if(peek(1) == '<' && peek(2)=='=') {
                        addToken(EToken.LANGLE2_EQUAL);
                    } else if(peek(1)=='<') {
                        addToken(EToken.LANGLE2);
                    } else {
                        addToken(EToken.LANGLE); 
                    }
                    break;
                case '>': 
                    if(peek(1)=='=') {
                        addToken(EToken.RANGLE_EQUAL);
                    } else if(peek(1) == '>' && peek(2)=='=') {
                        addToken(EToken.RANGLE2_EQUAL);
                    } else if(peek(1)=='>') {
                        addToken(EToken.RANGLE2);
                    } else {
                        addToken(EToken.RANGLE); 
                    }
                    break;

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
