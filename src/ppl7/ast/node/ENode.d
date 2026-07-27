module ppl7.ast.node.ENode;

import ppl7.all;

enum ENode {
    // Nodes
    ADDRESS_OF,
    ALIAS,
    ARRAY_LITERAL,
    AS,
    ASSERT,
    BINARY,
    BREAK,
    BUILTIN,
    CALL,
    CONTINUE,
    DOT,
    ENUM,
    ENUM_MEMBER,
    FOR,
    FUNCTION,
    IDENTIFIER,
    IF,
    INDEX,
    IS,
    MODULE,
    MODULE_REF,
    NODE_REF,
    NUMBER,
    PARENS,
    RETURN,
    STRING_LITERAL,
    STRUCT_LITERAL,
    NULL,
    UNARY,
    VALUE_OF,
    VARIABLE,

    // Types
    ARRAY_TYPE,
    SIMPLE_TYPE,
    POINTER_TYPE,
    STRUCT,
    TYPE_OF,
    TYPE_REF,
}
