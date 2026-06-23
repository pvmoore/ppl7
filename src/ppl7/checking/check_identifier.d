module ppl7.checking.check_identifier;

import ppl7.all;

void checkIdentifier(Identifier n) {
    
    // Check for modifying a const
    if(Binary b = n.getAncestor!Binary) {
        if(b.op.isAssign() && b.isOnLeft(n) && n.target.isConst()) {
            semanticError(n, EError.BINARY_MODIFYING_CONSTANT);
        }
    }

    // Check visibility
    if(!n.target.isPublic()) {

        // This is ok if the target is in the same module
        if(n.target.isRemote()) {
            
            semanticError(n, EError.IDENTIFIER_NOT_VISIBLE);
        }
    }
}
