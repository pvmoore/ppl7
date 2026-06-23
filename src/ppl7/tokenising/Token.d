module ppl7.tokenising.Token;

import ppl7.all;

immutable Token NO_TOKEN = Token(EToken.NONE, null, 0, 0);

struct Token {
    EToken kind;
    string text;

    uint line;
    uint column;

    string toString() { return "Token(%s '%s' %s:%s)".format(kind, text, line, column); }
}

Token makeToken(EToken kind, string text, uint line, uint column) {
    return Token(kind, text, line, column);
}
