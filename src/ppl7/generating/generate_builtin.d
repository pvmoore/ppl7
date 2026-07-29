module ppl7.generating.generate_builtin;

import ppl7.all;

void generateBuiltin(Builtin n, GenerateState state) {
    assert(n.name.isOneOf("@pointerAdd"));

    Expression[] args = n.arguments();
    PointerType p = args[0].getType().extract!PointerType; assert(p);
    LLVMTypeRef elementType = state.getLLVMType(p.valueType());

    state.generate(args[0]);
    auto ptr = state.rhs;

    // rhs
    state.generate(args[1]);
    auto right = state.castType(state.rhs, args[1].getType(), STATIC_LONG);

    // Negate the index
    // if(n.name == "@pointerSub") {
    //     right = LLVMBuildNeg(state.builder, right, null.toStringz());
    // }

    LLVMValueRef[] indices = [right];
    state.rhs = LLVMBuildInBoundsGEP2(state.builder, elementType, ptr, indices.ptr, 1, null.toStringz());
}
