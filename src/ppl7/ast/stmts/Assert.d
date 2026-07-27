module ppl7.ast.stmts.Assert;

import ppl7.all;

/**
 * Assert
 *     Expression
 */
final class Assert : Statement {
public:
    this() {
        _type = makeVoidType();
    }

    // Node
    override ENode enode() { return ENode.ASSERT; }
    override bool isResolved() { return false; }

    // Statement
    override Type getType() { return _type; }

    Expression expr() { return first().as!Expression; }

    override string toString() {
        string[] info;
        return "Assert %s".format(info);
    }
private:
    Type _type;
}

