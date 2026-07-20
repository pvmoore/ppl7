module ppl7.ast.stmts.Statement;

import ppl7.all;

abstract class Statement : Node {
public:
    int tokenIndex;
    bool resolveEvaluated;

    abstract Type getType();

    Token startToken() {
        auto tokens = getModule().tokens;
        if(tokenIndex <0 || tokenIndex >= tokens.length) {
            return NO_TOKEN;
        }
        return tokens[tokenIndex];
    }
    int line() { return startToken().line; }

protected:
}
