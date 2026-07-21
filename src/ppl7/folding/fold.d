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

void fold(Identifier n, ResolveState state) {
    assert(n.isResolved());

    // Only fold identifiers with a variable target atm
    auto var = n.target.var;
    if(!var) return;

    // Variable must be const
    if(!var.isConst) return;

    // Only fold integers and reals
    Type type = n.getType();
    if(!type.isInteger() && !type.isReal()) return;

    // Ignore if identifier is a child of AddressOf
    if(n.hasAncestor(ENode.ADDRESS_OF)) return;

    if(auto b = n.getAncestor!Binary) {

        // This identifier is being assigned to. This should only happen if there is a compilation error
        if(b.op.isAssign() && b.isOnLeft(n)) return;
    }

    auto num = var.initialiser().as!Number;
    if(!num) return;

    //writefln("[%s:%s] folding identifier %s to %s", n.getModule().name, n.line()+1, n, num);

    // We can replace the Identifier with the constant value
    rewrite(state, n, makeNodeRef(num));
}

void fold(Variable n, ResolveState state) {
    assert(n.isResolved());

    // if(n.hasInitialiser()) {
    //     // If the initialiser is the same as the default initialiser then we can remove it

    //     Expression init = n.initialiser();
    //     if(!init.isResolved()) return;

    //     Type type = n.getType();
    //     bool canRemove = false;

    //     if(type.isPointer()) {
    //         if(init.isA!Null) {
    //             canRemove = true;
    //         }
    //     } else if(type.isInteger() || type.isReal()) {
    //         if(Number num = init.as!Number) {
    //             if(num.isZero()) {
    //                 canRemove = true;
    //             }
    //         }
    //     }

    //     if(canRemove) {
    //         writefln("[%s:%s] Removing explicit Variable initialiser %s", n.getModule().name, n.line()+1, n.name);
    //         n.remove(init);
    //         state.setRewriteOccurred();
    //     }
    // }
    if(n.hasInitialiser()) {
        // If the Variable type is bool and the initialiser is an integer then wrap the initialiser in a != 0 comparison

        Expression init = n.initialiser();
        if(!init.isResolved()) return;

        if(n.getType().isBool()) {
            Type initType = init.getType();

            if(initType.isInteger()) {
                n.add(makeBinary(Operator.NOT_EQUAL, init, makeIntNumber(0, initType), makeBoolType()));
                state.setRewriteOccurred();
            }
        }
    }
}
