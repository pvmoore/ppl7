module ppl7.parsing.attributes;

import ppl7.all;

enum NO_ATTRIBUTE = Attribute(null, null, false);

struct Attribute {
    string name;
    string value;
    bool openScope;
    Token token;
}

/**
 * #(name)
 *
 * #(packed)
 * #(name=x) eg. #(name=itoa)
 */
final class Attributes {
public:
    bool hasAttribute(string name) {
        return !chain(singleStatementAttributes, multiStatementAttributes).find!(a => a.name == name).empty;
    }
    Attribute getAttribute(string name) {
        return chain(singleStatementAttributes, multiStatementAttributes).find!(a => a.name == name).frontOrElse!Attribute(NO_ATTRIBUTE);
    }
    Attribute[] getCurrentAttributes() {
        return singleStatementAttributes ~ multiStatementAttributes;
    }

    void parse(ParseState state) {
        singleStatementAttributes.length = 0;
        state.skipSemicolons();

        // Consume Attributes
        while(state.etoken() == EToken.HASH) {
            if(state.etoken(1) == EToken.IDENTIFIER && state.text(1) == "end") {
                state.skip(EToken.HASH);
                state.skip("end");

                if(multiStatementAttributes.length == 0) {
                    syntaxError(state, "Unexpected #end");
                }

                // scope name
                state.skip(EToken.LPAREN);
                if(state.text() != multiStatementAttributes.last().name) {
                    syntaxError(state, "Expected #end(%s) but found #end(%s)".format(multiStatementAttributes.last().name, state.text()));
                }
                state.next();
                state.skip(EToken.RPAREN);

                multiStatementAttributes.length--;
            } else {
                Attribute attr = parseAttribute(state);
                if(attr.openScope) {
                    multiStatementAttributes ~= attr;
                } else {
                    singleStatementAttributes ~= attr;
                }
            }
            state.skipSemicolons();
        }
    }
    override string toString() {
        return "Attributes %s".format(getCurrentAttributes().map!(a => a.name).join(", "));
    }
private:
    Attribute[] singleStatementAttributes;
    Attribute[] multiStatementAttributes;
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

/**
 *  { '#' [ 'begin' ] '(' name [ '=' value ] ')' }
 */
Attribute parseAttribute(ParseState state) {

    if(state.etoken() == EToken.HASH) {

        Attribute attr;

        state.skip(EToken.HASH);

        // Open a scope for this attribute
        if(state.text() == "begin") {
            attr.openScope = true;
            attr.token = state.token();
            state.next();
        }

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

            if(attr.name == "ABI") {
                attr.value = attr.value.toUpper();
            }
        } else {
            if(attr.name == "ABI") {
                syntaxError(state, "ABI attribute requires a value");
            }
        }

        state.skip(EToken.RPAREN);

        return attr;
    }
    return NO_ATTRIBUTE;
}

bool isRecognisedAttribute(string name) {
    switch(name) {
        case "ABI":
        case "packed":
        case "inline":
        case "name":
        case "noinline":
        case "unqualified":
            return true;
        default: return false;
    }
}
