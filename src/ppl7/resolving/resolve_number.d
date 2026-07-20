module ppl7.resolving.resolve_number;

import ppl7.all;
import std.conv     : to;
import std.string   : toLower;

/**
 * true
 * false
 *
 * 123      (int)
 * 123L
 *
 * 0x123    (ubyte)
 * 0b101010 (ubyte)
 *
 * 123.4    (float)
 * 123d     (double)
 *
 * 123.4e5  *todo
 *
 * 'c', '\n', '\x12', '\u1234', '\U12345678' (uint)  we will turn chars into uint
 */
void resolveNumber(Number n, ResolveState state) {
    if(n.isResolved()) return;

    if("true" == n.stringValue) {
        n.value.byteValue = -1;
        n.setType(makeBoolType());
        return;
    }
    if("false" == n.stringValue) {
        n.value.byteValue = 0;
        n.setType(makeBoolType());
        return;
    }


    // Check for a character literal
    if(n.stringValue[0] == '\'') {
        resolveChar(n, state);
        return;
    }

    string s = n.stringValue.toLower().replace("_", "");

    if(s.contains(".") || s.endsWith("d")) {
        resolveReal(n, s);
    } else {
        resolveInteger(n, s);
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void resolveReal(Number n, string s) {
    bool isDouble = false;

    if(s.endsWith("d")) {
        s = s[0..$-1];
        isDouble = true;
    }

    if(isDouble) {
        n.setType(makeDoubleType());
    } else {
        n.value.floatValue = s.to!float;
        n.setType(makeFloatType());
    }
}

void resolveInteger(Number n, string s) {

    // Assume the number is an int unless it is definitely a long
    uint size = 4;

    if(s.endsWith("l")) {
        size = 8;
        s = s[0..$-1];
    }

    if(s.startsWith("0x")) {
        s = s[2..$];
        if(s.length > 8) {
            size = 8;
        }
        s = s.to!ulong(16).to!string;

    } else if(s.startsWith("0b")) {
        s = s[2..$];
        if(s.length > 32) {
            size = 8;
        }
        s = s.to!ulong(2).to!string;
    }

    // int.min  = -2147483648
    // int.max  = 2147483647
    // long.min = -9223372036854775808
    // long.max = 9223372036854775807

    EType tk;

    if(s.startsWith("-")) {
        long v = s.to!long;

        // Only allow negative integers above int.min before switching to long
        if(v < int.min || v > int.max) size = maxOf(size, 8);

        switch(size) {
            case 4: n.value.intValue  = v.as!int;  tk = EType.INT; break;
            case 8: n.value.longValue = v.as!long; tk = EType.LONG; break;
            default: assert(false);
        }
    } else {
        ulong v = s.to!ulong;

        // Allow positive integers up to uint.max before switching to long
        if(v > uint.max) size = maxOf(size, 8);

        switch(size) {
            case 4: n.value.intValue  = v.as!int;  tk = EType.INT; break;
            case 8: n.value.longValue = v.as!long; tk = EType.LONG; break;
            default: assert(false);
        }
    }
    //log("number %s (%s, %s) size = %s", s, s.to!long, s.to!long.as!ulong, size);

    n.setType(makeSimpleType(tk));
}

void resolveChar(Number n, ResolveState state) {
    auto t = state.resolveChar(n, n.stringValue[1..$-1]);
    n.value.intValue = t[0];
    n.setType(makeIntType());
}
