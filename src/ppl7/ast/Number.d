module ppl7.ast.Number;

import ppl7.all;

/**
 * Number
 *
 * Todo - Use makeNumber instead of makeXNumber variations.
 */
final class Number : Expression {
public:
    string stringValue;
    Value_T value;

    static union Value_T {
        byte byteValue;
        short shortValue;
        int intValue;
        long longValue;
        float floatValue;
        double doubleValue;
    }

    this() {
        _type = makeUnknownType();
    }

    // Node
    override ENode enode() { return ENode.NUMBER; }
    override bool isResolved() { return _type.isResolved(); }

    // Statement
    override Type getType() { return _type; }

    // Expression
    override int precedence() { return Precedence.LOWEST; }

    bool isZero() {
        switch(_type.etype()) {
            case EType.BOOL:   return value.byteValue == 0;
            case EType.BYTE:   return value.byteValue == 0;
            case EType.SHORT:  return value.shortValue == 0;
            case EType.INT:    return value.intValue == 0;
            case EType.LONG:   return value.longValue == 0;
            case EType.FLOAT:  return value.floatValue == 0.0;
            case EType.DOUBLE: return value.doubleValue == 0.0;
            default: assert(false, "We shouldn't get here. type is %s".format(_type.etype()));
        }
        assert(false);
    }

    void setType(Type type) { this._type = type; }

    override string toString() {
        string[] info;
        if(!isResolved()) info ~= "UNRESOLVED"; else info ~= "%s".format(_type);
        return "%s %s".format(stringValue, info.join(", "));
    }

    // bool getValueAsBool() {
    //     switch(_type.etype()) {
    //         case EType.BOOL:   return value.byteValue != 0;
    //         case EType.BYTE:   return value.byteValue != 0;
    //         case EType.SHORT:  return value.shortValue != 0;
    //         case EType.INT:    return value.intValue != 0;
    //         case EType.LONG:   return value.longValue != 0;
    //         case EType.FLOAT:  return value.floatValue != 0.0;
    //         case EType.DOUBLE: return value.doubleValue != 0.0;
    //         default: assert(false, "We shouldn't get here. type is %s".format(_type.etype()));
    //     }
    // }
    int getValueAsInt() {
        switch(_type.etype()) {
            case EType.BYTE:   return value.byteValue;
            case EType.SHORT:  return value.shortValue;
            case EType.INT:    return value.intValue;
            case EType.LONG:   return value.longValue.as!int;
            case EType.FLOAT:  return value.floatValue.as!int;
            case EType.DOUBLE: return value.doubleValue.as!int;
            default: assert(false);
        }
    }
    // float getValueAsFloat() {
    //     switch(_type.etype()) {
    //         case EType.BYTE:   return value.byteValue;
    //         case EType.SHORT:  return value.shortValue;
    //         case EType.INT:    return value.intValue;
    //         case EType.LONG:   return value.longValue;
    //         case EType.FLOAT:  return value.floatValue;
    //         case EType.DOUBLE: return value.doubleValue.as!float;
    //         default: assert(false);
    //     }
    // }
    // double getValueAsDouble() {
    //     switch(_type.etype()) {
    //         case EType.BYTE:   return value.byteValue;
    //         case EType.SHORT:  return value.shortValue;
    //         case EType.INT:    return value.intValue;
    //         case EType.LONG:   return value.longValue;
    //         case EType.FLOAT:  return value.floatValue;
    //         case EType.DOUBLE: return value.doubleValue;
    //         default: assert(false);
    //     }
    // }
    void setValue(int v) {
        stringValue = "%s".format(v);
        switch(_type.etype()) {
            case EType.BYTE:   value.byteValue = v.as!byte; break;
            case EType.SHORT:  value.shortValue = v.as!short; break;
            case EType.INT:    value.intValue = v; break;
            case EType.LONG:   value.longValue = v.as!long; break;
            case EType.FLOAT:  value.floatValue = v.as!float; break;
            case EType.DOUBLE: value.doubleValue = v.as!double; break;
            default: assert(false);
        }
    }
private:
    Type _type;
}

//──────────────────────────────────────────────────────────────────────────────────────────────────

Number makeNumber(string value, Type type) {
    auto n = makeNode!Number(0);
    n.stringValue = value;
    switch(type.etype()) {
        case EType.BOOL:   n.value.byteValue = value.toBool() ? -1 : 0; break;
        case EType.BYTE:   n.value.byteValue = value.toInt().as!byte; break;
        case EType.SHORT:  n.value.shortValue = value.toInt().as!short; break;
        case EType.INT:    n.value.intValue = value.toInt(); break;
        case EType.LONG:   n.value.longValue = value.toLong(); break;
        case EType.FLOAT:  n.value.floatValue = value.toFloat(); break;
        case EType.DOUBLE: n.value.doubleValue = value.toDouble(); break;
        default: assert(false, "We shouldn't get here. type is %s".format(type.etype()));
    }
    n.setType(type);
    return n;
}

Number makeBoolNumber(bool b) {
    auto n = makeNode!Number(0);
    n.stringValue = b ? "true" : "false";
    n.value.byteValue = b ? -1 : 0;
    n.setType(makeBoolType());
    return n;
}
Number makeIntNumber(int value, Type type = null) {
    auto n = makeNode!Number(0);
    n.stringValue = "%s".format(value);
    n.value.intValue = value;
    if(type is null) {
        n.setType(makeIntType());
    } else {
        n.setType(type);
    }
    return n;
}
Number makeLongNumber(long value) {
    auto n = makeNode!Number(0);
    n.stringValue = "%s".format(value);
    n.value.longValue = value;
    n.setType(makeLongType());
    return n;
}
Number makeFloatNumber(float value) {
    auto n = makeNode!Number(0);
    n.stringValue = "%.5f".format(value);
    n.value.floatValue = value;
    n.setType(makeFloatType());
    return n;
}
Number makeDoubleNumber(double value) {
    auto n = makeNode!Number(0);
    n.stringValue = "%.8f".format(value);
    n.value.doubleValue = value;
    n.setType(makeDoubleType());
    return n;
}
