module ppl7.ast.Builtin;

import ppl7.all;

/**
 * Builtin
 *     { Expression }  arguments
 *
 * @debug(Expression)
 *
 * @isArray(Expression)     
 * @isBool(Expression)      
 * @isConst(Expression)     *todo add @isMutable(xxx)
 * @isEnum(Expression)      
 * @isFunction(Expression)  
 * @isInteger(Expression)   
 * @isPacked(Type)         
 * @isPointer(Expression)   
 * @isPublic(Expression)    
 * @isReal(Expression)      
 * @isStruct(Expression)    
 * @isUnion(Expression)     *todo
 * @isValue(Expression)     
 * @isVoid(Expression)    
 *  
 * @alignOf(Expression)     
 * @initOf(Expression)      *todo
 * @offsetOf(Expression)   
 * @sizeOf(Expression)   
 *
 * @property(Type, StringLiteral, [StringLiteral])   
 */
final class Builtin : Expression {
public:
    this() {
        _type = makeUnknownType();
    }

    string name;

    override ENode enode() { return ENode.BUILTIN; }
    override bool isResolved() { return false; }

    // Statement
    override Type getType() { return _type; }

    // Expression
    override int precedence() { return Precedence.CALL; }

    Expression[] arguments() { return children.map!(v=>v.as!Expression).array; }

    override string toString() {
        return "Builtin %s".format(name);
    }
private:
    Type _type;
}

