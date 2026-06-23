module ppl7.ast.types.SimpleType;

import ppl7.all;

final class SimpleType : Type {
public:
    // Node
    override ENode enode() { return ENode.BASIC_TYPE; }
    override bool isResolved() { return _etype != EType.UNKNOWN; }

    // Type
    override EType etype() { return _etype; }

    override bool exactlyMatches(Type other) {
        if(other.isPointer()) return false;
        if(SimpleType o = other.extract!SimpleType()) {
            return _etype == o._etype;
        }
        return false;
    }
    override bool canImplicitlyCastTo(Type other) {
        if(other.isPointer()) return false;
        if(SimpleType o = other.extract!SimpleType()) {

            // Allow any type to be cast to bool
            if(other.isBool()) return true;

            if(this.isReal()) {
                if(other.isReal()) return other.etype() >= this.etype();
            } else if(this.isInteger()) {
                if(other.isReal()) return true;
                if(other.isInteger()) return other.size() >= this.size();
            } else {
                return _etype == o._etype;
            }
        }
        return false;
    }
    override string shortName() { return this.toString(); }

    override string mangledName() {
        switch(_etype) {
            case EType.BOOL: return "B";
            case EType.BYTE: return "b";
            case EType.SHORT: return "s";
            case EType.INT: return "i";
            case EType.LONG: return "l";
            case EType.FLOAT: return "f";
            case EType.DOUBLE: return "d";
            case EType.VOID: return "v";
            case EType.C_VARARGS: return "V";
            default: assert(false); 
        }
    }

    void setEType(EType tk) { _etype = tk; } 

    override string toString() {
        string s;
        switch(_etype) {
            case EType.UNKNOWN: s = "unknown"; break;
            case EType.VOID: s = "void"; break;
            case EType.BOOL: s = "bool"; break;
            case EType.BYTE: s = "byte"; break;
            case EType.SHORT: s = "short"; break;
            case EType.INT: s = "int"; break;
            case EType.LONG: s = "long"; break;
            case EType.FLOAT: s = "float"; break;
            case EType.DOUBLE: s = "double"; break;
            case EType.C_VARARGS: s = "..."; break;
            default: assert(false); 
        } 
        return "%s".format(s);
    }
private:
    EType _etype = EType.UNKNOWN;
}

Type makeBoolType() { return makeSimpleType(EType.BOOL); }
Type makeByteType() { return makeSimpleType(EType.BYTE); }
Type makeShortType() { return makeSimpleType(EType.SHORT); }
Type makeIntType() { return makeSimpleType(EType.INT); }
Type makeLongType() { return makeSimpleType(EType.LONG); }
Type makeFloatType() { return makeSimpleType(EType.FLOAT); }
Type makeDoubleType() { return makeSimpleType(EType.DOUBLE); }
Type makeVoidType() { return makeSimpleType(EType.VOID); }
Type makeUnknownType() { return makeSimpleType(EType.UNKNOWN); }

Type makeSimpleType(EType tk) { 
    auto t = makeNode!SimpleType(0);
    t._etype = tk;
    return t; 
}
