module ppl7.folding.fold;

import ppl7.all;

void fold(As n, ResolveState state) {
    assert(n.isResolved());

    Type lt = n.leftType();     assert(lt);
    Type rt = n.rightType();    assert(rt);

    if(auto num = n.expr().as!Number) {

        if(rt.isA!SimpleType) {
            // We can convert the Number to the correct type now and remove the As node

            num.setType(rt);

            rewrite(state, n, n.expr());
            return;
        }
    }
}

void fold(Binary n, ResolveState state) {
    Expression left = n.left();
    Expression right = n.right();

    if(!left.isResolved() || !right.isResolved()) return;

    // Let's see if we can fold this expression

    if(n.op.isAssign()) {

    } else {

    }
}
