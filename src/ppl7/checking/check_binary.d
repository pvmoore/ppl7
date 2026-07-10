module ppl7.checking.check_binary;

import ppl7.all;

void checkBinary(Binary n) {

    // Unsigned operators can only be used with integers
    if(n.op.isUnsigned()) {
        if(!n.leftType().isInteger() || !n.rightType().isInteger()) {
            semanticError(n, EError.BINARY_UNSIGNED_WITH_REAL);
        }
    }

    // If operator is one of shl, shr, ushr then the type must be an integer
    if(n.op.isOneOf(Operator.SHL, Operator.SHR, Operator.USHR)) {
        if(!n.leftType().isInteger() || !n.rightType().isInteger()) {
            semanticError(n, EError.BINARY_SHIFT_REQUIRES_INTEGER);
        }
    }

    if(n.op.isAssign()) {
        checkAssignment(n);
    }
    // If this is a boolean and/or then check that the order of precendence is not ambiguous
    if(n.op.isOneOf(Operator.BOOL_AND, Operator.BOOL_OR)) {
        if(n.left().isA!Binary && n.left().as!Binary.op.isOneOf(Operator.BOOL_AND, Operator.BOOL_OR, Operator.EQUAL)) {
            semanticError(n, EError.BINARY_REQUIRES_PARENTHESES);
        }
        if(n.right().isA!Binary && n.right().as!Binary.op.isOneOf(Operator.BOOL_AND, Operator.BOOL_OR, Operator.EQUAL)) {
            semanticError(n, EError.BINARY_REQUIRES_PARENTHESES);
        }
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void checkAssignment(Binary n) {
    // Check that the right hand side can be cast to the left hand side
    if(!n.rightType().canImplicitlyCastTo(n.leftType())) {
        log(n.getModule(), "Binary: Cannot cast %s to %s", n.rightType(), n.leftType());
        semanticError(n, EError.BINARY_ASSIGNMENT_TYPE_MISMATCH);
    }

    // Assigning via an immutable ptr dereference
    if(auto v = n.left().as!ValueOf) {
        if(v.expr().getType().isImmutable()) {
            semanticError(n, EError.BINARY_ASSIGNMENT_TO_IMMUTABLE);
        }
        return;
    }
    // Assigning via an immutable ptr index
    if(auto idx = n.left().as!Index) {
        if(idx.expr().getType().isImmutable()) {
            semanticError(n, EError.BINARY_ASSIGNMENT_TO_IMMUTABLE);
        }
        return;
    }

    // Assigning to a const variable
    if(auto id = n.left().extract!Identifier) {
        if(id.target.isConst()) {
            semanticError(n, EError.BINARY_ASSIGNMENT_TO_CONST);}
    }// Assigning via an immutable ptr index
    if(auto idx = n.left().as!Index) {
        if(idx.expr().getType().isImmutable()) {
            semanticError(n, EError.BINARY_ASSIGNMENT_TO_IMMUTABLE);
        }
    }

    auto lhsId = n.left().extract!Identifier;
    assert(lhsId, "Expected Identifier on left hand side but was %s".format(n.left().enode()));
}
