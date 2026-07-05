module ppl7.ast.stmts.Statement;

import ppl7.all;

abstract class Statement : Node {
public:
    int tokenIndex;
    bool resolveEvaluated;

    abstract Type getType();

    Token startToken() { return getModule().tokens[tokenIndex]; }
    int line() { return startToken().line; }

protected:
}
