module ppl7.ast.types.Array;

import ppl7.all;

/**
 *  Array
 *      Type        elementType
 *      Number      numElements
 */
final class Array : Type {
public:
    LLVMTypeRef llvmType;

    // Node
    override ENode enode() { return ENode.ARRAY_TYPE; }
    override bool isResolved() {
        return elementType.isResolved() &&
               numElementsExpr().isResolved() &&
               numElementsExpr().extractNumber() !is null;
    }

    // Statement

    // Type
    override EType etype() { return EType.ARRAY; }

    override bool exactlyMatches(Type other) {
        assert(isResolved() && other.isResolved());
        if(Array o = other.as!Array) {
            return numElements == o.numElements && elementType.exactlyMatches(o.elementType);
        }
        return false;
    }
    override bool canImplicitlyCastTo(Type other) {
        if(Array o = other.as!Array) {
            // The length and element types must match
            return numElements() == o.numElements() && elementType.exactlyMatches(o.elementType);
        }
        return false;
    }

    override string shortName() { return "%s[]".format(elementType().shortName()); }
    override string mangledName() { return "A%s[%s]".format(elementType().mangledName(), numElements()); }

    Type elementType() {
        return first().as!Type;
    }
    Expression numElementsExpr() {
        return last().as!Expression;
    }
    int numElements() {
        assert(isResolved(), "Don't call this until the Array is resolved");
        assert(numElementsExpr().extractNumber() !is null, "numElement is not a Number");
        return numElementsExpr().extractNumber().value.intValue;
    }

    override string toString() {
        string numElementsStr = numElementsExpr().isA!Number ? numElementsExpr().as!Number.stringValue : "UNRESOLVED";
        return "[%s x %s]".format(elementType(), numElementsStr);
    }
}

Array makeArray(Type elementType, int numElements) {
    auto a =  makeNode!Array(0);
    a.add(elementType);
    a.add(makeIntNumber(numElements));
    return a;
}
