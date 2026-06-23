module ppl7.ast.types.Alias;

import ppl7.all;

/**
 * Alias
 *     Type
 */
final class Alias : Type {
public:
    string name;
    bool isPublic;

    // Node
    override ENode enode() { return ENode.ALIAS; }
    override bool isResolved() { return aliasedType().isResolved(); }

    // Type
    override EType etype() { return aliasedType().etype(); }

    override bool exactlyMatches(Type other) {
        return aliasedType.exactlyMatches(other);
    }
    override bool canImplicitlyCastTo(Type other) {
        return aliasedType.canImplicitlyCastTo(other);
    }

    Type aliasedType() { return first().as!Type; }

    override string shortName() { return name; }
    override string mangledName() { return aliasedType().mangledName(); }

    override string toString() {
        string[] info;
        if(name) info ~= "'%s'".format(name);
        if(isPublic) info ~= "public";
        return "Alias [%s]".format(info.join(", "));
    }
}
