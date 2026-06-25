module ppl7.parsing.attributes;

import ppl7.all;

enum NO_ATTRIBUTE = Attribute(null, null);

struct Attribute {
    string name;
    string value;
}

/**
 * #(inline)                        // functions
 * #(name=x)    eg. #(name=itoa)    // functions
 * #(noinline)                      // functions
 * #(packed)                        // structs and unions
 * #(unqualified)                   // enums
 */
final class Attributes {
public:
    bool hasAttribute(string name) {
        return attributes.any!(a => a.name == name);
    }
    Attribute getAttribute(string name) {
        return attributes.find!(a => a.name == name).frontOrElse!Attribute(NO_ATTRIBUTE);
    }
    Attribute[] getCurrentAttributes() {
        return attributes;
    }

    void parse(ParseState state) {
        attributes.length = 0;
        state.skipSemicolons();

        // Consume Attributes
        while(state.etoken() == EToken.HASH) {
            attributes ~= parseAttribute(state);
            state.skipSemicolons();
        }
    }
    override string toString() {
        return "Attributes %s".format(getCurrentAttributes().map!(a => a.name).join(", "));
    }
private:
    Attribute[] attributes;
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

/**
 *  { '#' '(' name [ '=' value ] ')' }
 */
Attribute parseAttribute(ParseState state) {

    if(state.etoken() == EToken.HASH) {

        Attribute attr;

        state.skip(EToken.HASH);
        state.skip(EToken.LPAREN);

        attr.name = state.text();

        if(state.hasAttribute(attr.name)) {
            syntaxError(state, "Duplicate '%s' attribute".format(attr.name));
        }

        state.next();

        if(!isRecognisedAttribute(attr.name)) {
            syntaxError(state, "Unrecognised attribute %s".format(attr.name));
        }

        if(state.etoken() == EToken.EQUAL) {
            state.skip(EToken.EQUAL);
            attr.value = state.text(); state.next();
        }

        state.skip(EToken.RPAREN);

        return attr;
    }
    return NO_ATTRIBUTE;
}

bool isRecognisedAttribute(string name) {
    switch(name) {
        case "packed":
        case "inline":
        case "name":
        case "noinline":
        case "unqualified":
            return true;
        default: return false;
    }
}
