module ppl7.checking.check_for;

import ppl7.all;

void checkFor(For n) {
    if(n.isWhile) {
        checkWhile(n);
    } else {
        checkSequence(n);
    }
}

private:

void checkSequence(For n) {
    assert(!n.isWhile);

    // If start and end are known at compile time:
    // (1) Start and end must be integer
    // (2) Start and end must have the correct direction
    // (3) If start == end then isInclusive must be true otherwise the loop will never execute

    // If there is a counter:
    // (4) (if there is a start and end then they must be implicitly convertable to counter type)

    Number start = getConstantNumber(n.start());
    Number end   = getConstantNumber(n.end());

    if(start && end) {

        // (1)
        if(!start.isInteger()) {
            semanticError(n.start(), EError.FOR_START_END_MUST_BE_INTEGER);
            return;
        }
        // (1)
        if(!end.isInteger()) {
            semanticError(n.end(), EError.FOR_START_END_MUST_BE_INTEGER);
            return;
        }

        // (2)
        long startValue = start.getAsLong();
        long endValue   = end.getAsLong();
        bool isForward  = startValue < endValue;
        bool isReverse  = startValue > endValue;
        bool equal      = startValue == endValue;

        if((n.isReversed && isForward) || (!n.isReversed && isReverse)) {
            semanticError(n.start(), EError.FOR_START_END_INCORRECT_DIRECTION);
            return;
        }

        // (3)
        if(equal && !n.isInclusive) {
            semanticError(n.start(), EError.FOR_START_END_EQUAL_BUT_NOT_INCLUSIVE);
            return;
        }
    }

    if(n.hasCounter) {
        Type counterType = n.counter().getType();

        // (4)
        if(!n.start().getType().canImplicitlyCastTo(counterType)) {
            semanticError(n.start(), EError.FOR_START_END_CANNOT_IMPLICITLY_CAST_TO_COUNTER_TYPE);
            return;
        }
        if(!n.end().getType().canImplicitlyCastTo(counterType)) {
            semanticError(n.end(), EError.FOR_START_END_CANNOT_IMPLICITLY_CAST_TO_COUNTER_TYPE);
            return;
        }
    }
}

void checkWhile(For n) {

}
