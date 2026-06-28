module ppl7.parsing.ParseState;

import ppl7.all;

final class ParseState {
public:
    int pos;
    Module mod;
    Token[] tokens;
    Project project;
    Attributes attributes;
    bool insidePublicScopeModule;
    bool insidePublicScopeStruct;

    this(Project project, Module mod) {
        this.project = project;
        this.mod = mod;
        this.tokens = mod.tokens;
        this.attributes = new Attributes;
    }

    bool hasAttribute(string name) {
        return attributes.hasAttribute(name);
    }
    Attribute getAttribute(string name) {
        return attributes.getAttribute(name);
    }

    bool eof() {
        return pos >= tokens.length;
    }
    Token token(int offset = 0) {
        return peek(offset);
    }
    EToken etoken(int offset = 0) {
        return token(offset).etoken;
    }
    string text(int offset = 0) {
        return token(offset).text;
    }
    uint line() {
        return token().line;
    }
    Token peek(int offset) {
        return pos + offset >= tokens.length ? NO_TOKEN : tokens[pos + offset];
    }
    auto next() {
        pos++;
        return this;
    }
    auto skip(string t, string msg = null) {
        if(text() != t) {
            syntaxError(mod, token(), "Expected %s but found %s%s".format(t, text(), msg ? ": %s".format(msg) : ""));
        }
        return next();
    }
    auto skip(EToken tk, string msg = null) {
        if(token().etoken != tk) {
            string found = token().etoken.stringOf();
            if(found.length == 0) found = text();
            syntaxError(mod, token(), "Expected %s but found %s%s".format(tk.stringOf(), found, msg ? ": %s".format(msg) : ""));
        }
        return next();
    }
    void skipSemicolons() {
        while(etoken() == EToken.SEMICOLON) {
            skip(EToken.SEMICOLON);
        }
    }
    bool isOnSameLine(int offset = 0) {
        return token(offset).line == peek(offset-1).line;
    }
    bool matches(int offset, EToken[] tk...) {
        foreach(t; tk) {
            if(etoken(offset++) != t) return false;
        }
        return true;
    }
    /**
     * Find the offset of the closing bracket. Assumes the current token is the opening bracket.
     * If the opening bracket is not found then returns -1.
     */
    int findOffsetOfClosing(int startOffset, EToken open, EToken close)
        in(token(startOffset).etoken == open)
        out(r; r == -1 || peek(r).etoken == close)
    {
        int p = this.pos + startOffset;
        int depth = 0;
        while(p < tokens.length) {
            if(tokens[p].etoken == open) {
                depth++;
            } else if(tokens[p].etoken == close) {
                depth--;
                if(depth == 0) return p-pos;
            }
            p++;
        }
        return -1;
    }
    /**
     * Find the offset of tok within the current scope. Assumes the current token is the opening bracket.
     * The current scope is defined as the tokens between the opening and closing bracket
     * and excludes nested scopes.
     * If the opening bracket is not found then returns -1.
     */
    // int findWithinScope(EToken open, EToken close, EToken tok)
    //     in(token().kind == open)
    //     out(r; r == -1 || peek(r).kind == tok)
    // {
    //     int p = this.pos;
    //     int depth = 0;
    //     while(p < tokens.length) {
    //         if(tokens[p].kind == open) {
    //             depth++;
    //         } else if(tokens[p].kind == close) {
    //             depth--;
    //             if(depth == 0) return -1;
    //         } else if(tokens[p].kind == tok) {
    //             if(depth == 1) return p-pos;
    //         }
    //         p++;
    //     }
    //     return -1;
    // }
private:
}
