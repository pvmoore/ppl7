module ppl7.checking.check_identifier;

import ppl7.all;

void checkIdentifier(Identifier n) {

    checkVisibility(n);
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void checkVisibility(Identifier n) {
    if(!n.target.isPublic()) {

        // This is ok if the target is in the same module
        if(n.target.isRemote()) {
            semanticError(n, EError.IDENTIFIER_NOT_VISIBLE);
        }
    }
}
