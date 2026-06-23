module ppl7.tokenising.Token;

import ppl7.all;

immutable Token NO_TOKEN = Token(EToken.NONE, null, 0, 0);

struct Token {
    EToken etoken;
    string text;

    uint line;
    uint column;

    string toString() { return "Token(%s '%s' %s:%s)".format(etoken, text, line, column); }
}

Token makeToken(EToken etoken, string text, uint line, uint column) {
    return Token(etoken, text, line, column);
}
