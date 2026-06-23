module ppl7.ast.types.Type;

import ppl7.all;

abstract class Type : Expression {
public:
    // Statement
    override Type getType() { return this; }

    // Expression
    override int precedence() { return Precedence.LOWEST; }
    
    // Type
    abstract EType etype();
    abstract bool exactlyMatches(Type);
    abstract bool canImplicitlyCastTo(Type);

    abstract string shortName();
    abstract string mangledName();
}

//──────────────────────────────────────────────────────────────────────────────────────────────────

T extract(T)(Type t) if(is(T : Type)) {
    if(T o = t.as!T) return o;
    if(TypeRef tr = t.as!TypeRef) return extract!T(tr.type);
    if(Alias a = t.as!Alias) return extract!T(a.aliasedType());
    if(PointerType pt = t.as!PointerType) return extract!T(pt.valueType());
    return null;
}

bool isVoidValue(Type t) { return t.etype() == EType.VOID && !t.isPointer(); }
bool isInteger(Type t)   { return t.etype() >= EType.BYTE && t.etype() <= EType.LONG; }
bool isReal(Type t)      { return t.etype() == EType.FLOAT || t.etype() == EType.DOUBLE; }
bool isBool(Type t)      { return t.etype() == EType.BOOL; }
bool isPointer(Type t)   { return t.etype() == EType.POINTER || t.etype() == EType.FUNCTION; }
bool isValue(Type t)     { return !isPointer(t); }
bool isVararg(Type t)    { return t.etype() == EType.C_VARARGS; }

bool isFunction(Type t) { 
    return t.etype() == EType.FUNCTION; 
}
bool isArrayType(Type t) { 
    return t.etype() == EType.ARRAY; 
}
bool isStruct(Type t) { 
    return t.extract!Struct !is null; 
}
bool isAnonStruct(Type t) {
    if(Struct st = t.extract!Struct) return st.name is null;
    return false;
}
bool isEnum(Type t) { 
    return t.extract!Enum !is null; 
}

bool isPublic(Type t) {
    if(Struct st = t.extract!Struct) return st.isPublic;
    if(Enum en = t.extract!Enum) return en.isPublic;
    if(Alias al = t.extract!Alias) return al.isPublic;
    return true;
}

uint size(Type t) {
    final switch(t.etype()) {
        case EType.ARRAY: {
            // todo - account for alignment here
            ArrayType at = t.extract!ArrayType;
            return at.numElements() * size(at.elementType());
        }
        case EType.FUNCTION: 
            // todo - this is 8 if this is a function pointer, otherwise this might be an error
            return 8;
        case EType.STRUCT:
            return t.extract!Struct.getSize();    
        case EType.POINTER:
            return 8;
        case EType.BOOL: 
        case EType.BYTE: 
            return 1;
        case EType.SHORT: 
            return 2;
        case EType.INT: 
        case EType.FLOAT: 
            return 4;
        case EType.LONG: 
        case EType.DOUBLE: 
            return 8;
        case EType.ENUM:
            return size(t.extract!Enum.elementType());
        case EType.VOID: 
        case EType.UNKNOWN: 
        case EType.C_VARARGS:
            throwIf(true, "size(%s) not supported", t.etype()); 
            assert(false);
    }
    assert(false);
}

uint alignment(Type t) {
    if(t.isPointer()) return 8;
    switch(t.etype()) {
        case EType.BOOL: 
        case EType.BYTE: 
            return 1;
        case EType.SHORT: 
            return 2;
        case EType.INT: 
        case EType.FLOAT: 
            return 4;
        case EType.LONG: 
        case EType.DOUBLE: 
            return 8;
        case EType.ARRAY:
            return alignment(t.extract!ArrayType.elementType());
        case EType.STRUCT:
            return t.extract!Struct.getAlignment();
        case EType.ENUM:
            return alignment(t.extract!Enum.elementType());
        default:
            throwIf(true, "alignment(%s) not supported", t.etype()); 
            assert(false);
    }
    assert(false);
}



/**
 * Return the largest type of a or b.
 * Return null if they are not compatible.
 */
Type selectCommonType(Type a, Type b) {
    if(a.isVoidValue() || b.isVoidValue()) return null;

    if(a.exactlyMatches(b)) return a;

    if(a.isPointer() || b.isPointer()) return null;

    if(a.isStruct() || b.isStruct()) {
        throwIf(true, "Handle Structs here");
        return null;
    }
    if(a.isArrayType() || b.isArrayType()) {
        throwIf(true, "Handle ArrayTypes here");
        return null;
    }
    
    if(a.isFunction() || b.isFunction()) {
        throwIf(true, "Handle Functions here");
        return null;
    }

    if(a.isReal() == b.isReal()) {
        return a.etype() > b.etype() ? a : b;
    }
    if(a.isReal()) return a;
    if(b.isReal()) return b;
    return a;
}

bool exactlyMatches(Type[] a, Type[] b) {
    if(a.length != b.length) return false;
    foreach(i, t; a) {
        if(!t.exactlyMatches(b[i])) return false;
    }
    return true;
}
bool canImplicitlyCastTo(Type[] a, Type[] b) {
    if(a.length != b.length) return false;
    foreach(i, t; a) {
        if(!t.canImplicitlyCastTo(b[i])) return false;
    }
    return true;
}
string shortName(Type[] t) {
    return t.map!(v=>v.shortName()).join(", ");
}
