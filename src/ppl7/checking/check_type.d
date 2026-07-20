module ppl7.checking.check_type;

import ppl7.all;

void checkArray(Array n) {
    if(n.numElements() == 0) {
        semanticError(n, EError.ARRAY_ZERO_ELEMENTS);
    }
}

void checkEnum(Enum n) {
    if(n.numMembers() == 0) {
        semanticError(n, EError.ENUM_ZERO_MEMBERS);
    }
}
