module ppl7.resolving.ResolveState;

import ppl7.all;

final class ResolveState {
public:
    Project project;
    Module mod;
    int numUnresolved;
    int numIterations;
    bool rewriteOccurred;

    this(Project project, Module mod) {
        this.project = project;
        this.mod = mod;
    }
    void startIteration() {
        rewriteOccurred = false;
        numUnresolved = 0;
        unresolvedNodes.length = 0;
    }
    void finishIteration() {
        numIterations++;
    }
    void setUnresolved(Node n) {
        numUnresolved++;
        unresolvedNodes ~= n;
    }
    void setRewriteOccurred() {
        rewriteOccurred = true;
    }
    bool hasUnresolvedNodes() {
        return numUnresolved > 0;
    }
    string getReport() {
        string s = "%s%s".format("Unresolved: %s".format(numUnresolved), rewriteOccurred ? ", rewrites occurred" : "");
        return s;
    }
    void convertUnresolvedNodesToErrors() {
        EError ek;
        foreach(n; unresolvedNodes) {
            switch(n.enode()) {
                case ENode.IDENTIFIER:
                    ek = EError.IDENTIFIER_NOT_FOUND;
                    break;
                case ENode.CALL:
                    ek = EError.FUNCTION_NOT_FOUND;
                    break;
                case ENode.BINARY:
                case ENode.BUILTIN:
                case ENode.DOT:
                case ENode.IS:
                    // Ignore these. Assume there will be something else that is also unresolved
                    continue;
                default:
                    writefln("%s", n.getModule().dump());
                    throwIf(true, "convertUnresolvedNodesToErrors: module:%s node:%s", n.getModule().name, n.enode());
            }
            resolutionError(n.as!Statement, ek);
        }
    }
    /**
     * Try to resolve the type of a Node using the parent's type
     */
    Type resolveTypeFromParent(Node n) {
        auto parent = n.parent;
        assert(parent !is null, "parent is null. This should not happen");

        switch(parent.enode()) {
            case ENode.AS:
                As as = parent.as!As;
                return as.getType();

            case ENode.ADDRESS_OF: {
                AddressOf a = parent.as!AddressOf;
                // What should we do here?
                break;
            }
            case ENode.ARRAY_LITERAL: {
                ArrayLiteral al = parent.as!ArrayLiteral;
                if(al.isResolved()) {
                    return al.elementType();
                }
                break;
            }
            case ENode.BINARY: {
                Binary b = parent.as!Binary;
                // if(b.getType().isResolved()) return b.getType();
                return b.oppositeSideType(n);
            }
            case ENode.BUILTIN:
                // No information available
                break;
            case ENode.IS:
                return parent.as!Is.oppositeSideType(n);
            case ENode.UNARY: {
                Unary u = parent.as!Unary;
                Type t = u.getType();
                if(t.isResolved()) return t;
                return resolveTypeFromParent(u);
            }
            case ENode.VARIABLE:
                return parent.as!Variable.getType();
            case ENode.STRUCT_LITERAL: {
                StructLiteral sl = parent.as!StructLiteral;
                if(sl.getType().isResolved()) {
                    if(Struct st = sl.getStruct()) {
                        auto index = n.index();
                        if(sl.hasNamedArguments()) {
                            string name = sl.names[index];
                            if(Variable v = st.getMemberByName(name)) return v.getType();
                        } else {
                            if(Variable v = st.getMemberByIndex(index)) return v.getType();
                        }
                    }
                }
                break;
            }
            case ENode.CALL: {
                Call call = parent.as!Call;
                auto argIndex = n.index();
                if(call.target.isResolved()) {
                    // Set to the type of the function param
                    auto paramTypes = call.target.paramTypes();
                    if(argIndex < paramTypes.length) return paramTypes[argIndex];
                }
                break;
            }
            case ENode.ENUM_MEMBER:
                return parent.as!EnumMember.getEnum().elementType();
            case ENode.RETURN:
                return parent.as!Return.func().returnType();
            default: throwIf(true, "getTypeFromParent: %s", parent.enode());
        }
        return makeUnknownType();
    }
    /**
     * Resolve a character from a string literal.
     * Params:
     *  n - The statement that contains the string literal
     *  s - The string literal starting at the character to resolve
     * Returns the character value and the number of characters consumed from the string literal
     *
     * f  \n  \x12 \u1234 \U12345678
     */
    Tuple!(uint, uint) resolveChar(Statement n, string s) {
        import std.conv : to;

        uint len = 2;
        uint value;
        if(s[0]=='\\') {
            switch(s[1]) {
                case '0' : value = 0; break;
                case 'b' : value = 8; break;
                case 't' : value = 9; break;
                case 'n' : value = 10; break;
                case 'f' : value = 12; break;
                case 'r' : value = 13; break;
                case '\"': value = 34; break;
                case '\'': value = 39; break;
                case '\\': value = 92; break;
                case 'x' : len = 4; value = to!uint(s[2..4], 16); break;
                case 'u' : len = 6; value = to!uint(s[2..6], 16); break;
                //case 'U' : len = 10; value = to!ulong(s[2..10], 16);
                default:
                    syntaxError(n.getModule(), n.startToken, "Invalid escape sequence in string literal");
                    break;
            }
        } else {
            value = s[0].as!uint;
            len = 1;
        }
        return tuple(value, len);
    }
private:
    Node[] unresolvedNodes;
}
