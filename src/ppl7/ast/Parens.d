module ppl7.ast.Parens;

import ppl7.all;

/**
 * Parens
 *     Expression    
 */
final class Parens : Expression {
public:

    // Node
    override ENode enode() { return ENode.PARENS; }
    override bool isResolved() { return expr().isResolved(); }

    // Statement
    override Type getType() { return expr().getType(); }

    // Expression
    override int precedence() { return Precedence.LOWEST; }

    Expression expr() { return first().as!Expression; }
    
    override string toString() {
        return "()";
    }
}
