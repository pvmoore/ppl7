module ppl7.ast.stmts.For;

import ppl7.all;

/**
 * For
 *    [ Variable ]      counter
 *    Expression        start
 *    Expression        end
 *    { Statement }     body
 *
 * For (while)
 *    [ Variable]       counter
 *    Expression        condition
 *    { Statement }     body
 */
final class For : Statement {
    bool isWhile;       // true if this is a while loop
    bool hasCounter;    // true if there is a loop counter variable

    bool isReversed;    // true if this is a reversed loop  (assumes !isWhile)
    bool isInclusive;   // true if this is an inclusive loop (assumes !isWhile)

    // Populated during generation so that we can hook up any break/continue statements
    LLVMBasicBlockRef llvmBreakBlock;
    LLVMBasicBlockRef llvmContinueBlock;

    // Node
    override ENode enode() { return ENode.FOR; }
    override bool isResolved() { return true; }

    // Statement
    override Type getType() { return STATIC_VOID; }

    // sequence
    Expression start() {
        assert(!isWhile);
        return children[hasCounter ? 1 : 0].as!Expression;
    }
    Expression end() {
        assert(!isWhile);
        return children[hasCounter ? 2 : 1].as!Expression;
    }

    // while
    Expression condition() {
        assert(isWhile);
        return children[hasCounter ? 1 : 0].as!Expression;
    }

    // both
    Variable counter() { assert(hasCounter); return children[0].as!Variable; }
    Statement[] bodyStatements() {
        int i = 1;
        if(!isWhile) i++;
        if(hasCounter) i++;
        return children[i..$].as!(Statement[]);
    }

    override string toString() {
        string[] info;
        if(isWhile) info ~= "while";
        if(isReversed) info ~= "reversed";
        if(!isWhile && isInclusive) info ~= "inclusive";
        if(!isWhile && !isInclusive) info ~= "exclusive";
        if(hasCounter) info ~= "counter";
        return "For [%s]".format(info.join(", "));
    }
}
