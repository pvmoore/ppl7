module ppl7.resolving.resolve_variable;

import ppl7.all;

void resolveVariable(Variable n, ResolveState state) {
    if(!n.isResolved()) {
        // Wait for the Variable type to be resolved
        return;
    }

    if(n.hasInitialiser()) {
        // If the initialiser is the same as the default initialiser then we can remove it

        Expression init = n.initialiser();
        if(!init.isResolved()) return;

        Type type = n.getType();
        bool canRemove = false;

        if(type.isPointer()) {
            if(init.isA!Null) {
                canRemove = true;
            }
        } else if(type.isInteger() || type.isReal()) {
            if(Number num = init.as!Number) {
                if(num.isZero()) {
                    canRemove = true;
                }
            }
        }

        if(canRemove) {
            state.mod.log("Removing explicit Variable initialiser %s", n.name);
            n.parent.remove(init);
        }
    }
    if(n.hasInitialiser()) {
        // If the Variable type is bool and the initialiser is an integer then wrap the initialiser in a != 0 comparison

        if(n.getType().isBool()) {

            Expression init = n.initialiser();
            if(!init.isResolved()) return;

            Type initType = init.getType();

            if(initType.isInteger()) {
                n.add(makeBinary(Operator.NOT_EQUAL, init, makeIntNumber(0, initType), makeBoolType()));
                state.setRewriteOccurred();
            }
        }
    }
}
