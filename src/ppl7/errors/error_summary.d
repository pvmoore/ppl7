module ppl7.errors.error_summary;

import ppl7.all;

string getSummaryMessage(CompilationError error) {
    Statement stmt = error.stmt;

    switch(error.eerror()) with(EError) {

        case ARRAY_MISSING_LENGTH:
            return "Array is missing length argument";
        case ARRAY_ZERO_ELEMENTS:
            return "Array has zero elements";

        case ARRAY_LITERAL_NUM_ELEMENTS: {
            ArrayLiteral al = error.stmt.as!ArrayLiteral; assert(al);
            Array at = al.getType().as!Array; assert(at);
            return "Array literal has %s elements, but the array type requires %s".format(al.elements().length, at.numElements());
        }
        case ARRAY_LITERAL_ELEMENT_TYPE_MISMATCH: {
            Expression ele = error.stmt.as!Expression; assert(ele);
            ArrayLiteral al = ele.parent.as!ArrayLiteral; assert(al);
            Array at = al.getType().as!Array; assert(at);
            return "Cannot implicitly convert %s to the array element type %s".format(ele.getType(), at.elementType());
        }

        case BINARY_REQUIRES_PARENTHESES:
            return "Add parentheses to this expression to resolve ambiguity";
        case BINARY_UNSIGNED_WITH_REAL:
            return "Cannot use unsigned operator with real numbers";
        case BINARY_ASSIGNMENT_TYPE_MISMATCH:
            return "Cannot assign %s to %s".format(error.stmt.as!Binary.rightType().shortName(), error.stmt.as!Binary.leftType().shortName());
        case BINARY_ASSIGNMENT_TO_CONST:
            return "Cannot assign to a const variable";
        case BINARY_SHIFT_REQUIRES_INTEGER:
            return "Cannot shift a non-integer type";
        case BINARY_ASSIGNMENT_TO_IMMUTABLE:
            return "Cannot assign to immutable variable";

        case BUILTIN_PROPERTY_MISSING_TYPE:
            return "@property first argument must be a type";
        case BUILTIN_PROPERTY_MISSING_KEY:
            return "@property second argument must be a string literal";
        case BUILTIN_PROPERTY_INVALID_TYPE:
            return "@property type must be one of bool, byte, short, int, long, float, double";
        case BUILTIN_PROPERTY_NOT_DEFINED:
            return "@property(\"%s\") not defined and no default was provided".format(stmt.as!StringLiteral().stringValue);
        case BUILTIN_PROPERTY_INVALID_VALUE:
            return "@property value cannot be converted to the expected type";
        case BUILTIN_PROPERTY_INVALID_DEFAULT_VALUE:
            return "@property default value cannot be converted to the expected type";

        case BUILTIN_OFFSET_OF_NOT_MEMBER:
            return "@offsetOf() requires a struct member as the first argument";
        case BUILTIN_ISCONST_NOT_IDENTIFIER:
            return "::isConst() requires an identifier as the first argument";
        case BUILTIN_ISPUBLIC_NOT_IDENTIFIER_OR_TYPE:
            return "::isPublic() requires an identifier or type as the first argument";


        case CALL_AMBIGUOUS_FUNCTION: {
            return "Ambiguous function call: %s".format(stmt.as!Call().name);
            //string s2 = formatAmbiguousFunction(stmt.as!Call());
            //return s1 ~ "\n" ~ s2;
        }
        case CALL_ARGUMENT_TYPE_MISMATCH: {
            Expression arg = error.stmt.as!Expression; assert(arg);
            Call call = arg.parent.as!Call; assert(call);
            int index = call.arguments().indexOf(arg);
            Type paramType = call.target.func.paramTypes()[index];
            return "Cannot implicitly convert %s to the parameter type %s".format(arg.getType().shortName(), paramType.shortName());
        }

        case CAST_INVALID: {
            As a = error.stmt.as!As; assert(a);
            return "Cannot cast %s to %s".format(a.leftType().shortName(), a.rightType().shortName());
        }

        case ENUM_MISSING_INITIALISERS:
            return "Enum members must be explicitly initialised when the element type is not an integer or real";


        case FUNCTION_NOT_FOUND:
            return "Function not found: %s".format(stmt.as!Call().name);
        case FUNCTION_MISSING_RETURN:
            return "This function is missing a return statement";
        case FUNCTION_NON_EXTERN_MISSING_BODY:
            return "Non-extern function must have a body";
        case FUNCTION_MAIN_NOT_PUBLIC:
            return "The program entry function must be public";


        case VARIABLE_INITIALISER_TYPE_MISMATCH: {
            Expression initialiser = error.stmt.as!Expression; assert(initialiser);
            Variable v = initialiser.parent.as!Variable; assert(v);
            return "Cannot implicitly convert %s to %s".format(initialiser.getType().shortName(), v.getType().shortName());
        }

        case IDENTIFIER_NOT_FOUND: {
            Identifier id = stmt.as!Identifier();
            Struct st = id.parent.isA!Dot ? id.parent.as!Dot.container().getType().extract!Struct : null;
            if(st) {
                string structName = st ? st.name : id.parent.as!Dot.container().getType().toString();
                return "Member %s not found for struct %s".format(id.name, structName);
            }
            return "'%s' cannot be resolved to a variable or function".format(id.name);
        }
        case IDENTIFIER_NOT_VISIBLE:
            return "Identifier is not visible: %s".format(stmt.as!Identifier().name);


        case IF_MISSING_THEN_EXPRESSION:
            return "If expression requires an expression at the end of the 'then' block";
        case IF_MISSING_ELSE_EXPRESSION:
            return "If expression requires an expression at the end of the 'else' block";
        case IF_EXPRESSION_TYPE_MISMATCH:
            return "If expression requires the 'then' and 'else' expressions to be castable to the same type";

        case IS_AMBIGUOUS:
            return "Ambiguous 'is' expression. Use parentheses to clarify the intended meaning";

        case IS_TYPE_MISMATCH: {
            Is i = error.stmt.as!Is; assert(i);
            if(i.left().isA!Type) {
                return "(Type is Expression) is not valid. Use @typeOf here instead";
            }
            return "(Expression is Type) is not valid. Use @typeOf here instead";
        }

        case MODULE_MAIN_MISSING:
            return "Main module must have a program entry point function eg 'main' if targetType is EXE";

        case STRUCT_LITERAL_MEMBER_TYPE_MISMATCH: {
            Expression ele = error.stmt.as!Expression; assert(ele);
            StructLiteral sl = ele.parent.as!StructLiteral; assert(sl);
            Struct st = sl.getStruct(); assert(st);
            int index = sl.members().indexOf(ele);
            Variable var = st.members()[index];
            return "Cannot implicitly convert %s to the struct member type %s".format(ele.getType(), var.getType());
        }
        case STRUCT_LITERAL_ARGUMENT_NOT_FOUND: {
            Expression ele = error.stmt.as!Expression; assert(ele);
            StructLiteral sl = ele.parent.as!StructLiteral; assert(sl);
            int index = sl.members().indexOf(ele);
            string name = sl.names[index];
            return "Struct member '%s' not found".format(name);
        }
        case STRUCT_LITERAL_ARGUMENT_NOT_VISIBLE: {
            Token nameTok = error.mod.getToken(error.stmt.tokenIndex - 2);
            if(nameTok.etoken == EToken.IDENTIFIER) {
                return "Struct member '%s' is not visible".format(nameTok.text);
            }
            return "Struct member is not visible";
        }
        case STRUCT_LITERAL_MIXED_ARGUMENTS:
            return "Cannot mix named and unnamed arguments in a struct literal";
        case STRUCT_LITERAL_TOO_MANY_ARGUMENTS:
            return "Struct literal has too many arguments";
        case STRUCT_LITERAL_UNNAMED_ARGUMENT:
            return "Named struct literals require all arguments to be named";

        case STRUCT_MEMBER_UNNAMED:
            return "Struct member missing name";

        case SYNTAX:
            return error.extraInfo.as!StringErrorExtraInfo.msg;


        case TYPE_CANNOT_BE_IMMUTABLE:
            return "Only arrays or pointers can have immutable data";

        case VARIABLE_SHADOWING: {
            Variable v = error.stmt.as!Variable; assert(v);
            return "Variable '%s' shadows another variable in the same scope".format(v.name);
        }
        case VARIABLE_UNINITIALISED_CONST:
            return "Const variable is not initialised";
        case VARIABLE_PARAMETER_INITIALISER:
            return "Default parameter values are not allowed";
        case VARIABLE_ANON_STRUCT_CONST:
            return "Anonymous structs cannot have const members";
        case VARIABLE_CONST_NO_INITIALISER:
            return "Const variables must be initialised";

        default:
            return "Generic Error: %s".format(error.eerror());
    }
}
