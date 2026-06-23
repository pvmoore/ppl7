module ppl7.resolving.resolve_if;

import ppl7.all;

void resolveIf(If n, ResolveState state) {

    // Rewrite condition to bool if it is an integer or a pointer
    if(n.condition().isResolved()) {
        Type condType = n.condition().getType();

        if(condType.isPointer()) {
            n.addToFront(makeBinary(Operator.NOT_EQUAL, n.condition(), makeNull(condType), makeBoolType()));
            state.setRewriteOccurred();

        } else if(condType.isInteger()) {
            n.addToFront(makeBinary(Operator.NOT_EQUAL, n.condition(), makeIntNumber(0, condType), makeBoolType()));
            state.setRewriteOccurred();
        }
    }

    if(n.isExpression()) {
        auto thenExpr = n.lastThenStatement();
        auto elseExpr = n.lastElseStatement();

        if(thenExpr is null || !thenExpr.isA!Expression) {
            semanticError(n, EError.IF_MISSING_THEN_EXPRESSION);
        }
        if(elseExpr is null || !elseExpr.isA!Expression) {
            semanticError(n, EError.IF_MISSING_ELSE_EXPRESSION);
        }
        if(thenExpr is null || elseExpr is null) return;

        if(!n.thenType().isResolved() || !n.elseType().isResolved()) return;

        Type type = selectCommonType(n.thenType(), n.elseType());
        if(type is null) {
            semanticError(n, EError.IF_EXPRESSION_TYPE_MISMATCH);
            return;
        }

        n.setType(type);

        // todo - If then or else blocks contain a return this is an error


    } else {
        n.setType(makeVoidType());
    }
}
