module ppl7.generating.generate_for;

import ppl7.all;

/**
 * ------------------------------------------------------------------------------ forward sequence:
 * for:
 *   generate counter
 *   generate start
 *   counter = start
 *   generate end
 * condition:
 *   if counter < end (exclusive) or counter <= end (inclusive) goto body else goto exit
 * body:
 *   generate body
 *   increment counter
 *   jmp condition
 * exit:
 *
 * ------------------------------------------------------------------------------ reverse sequence:
 * for:
 *   generate counter
 *   generate start
 *   generate end
 *   counter = start
 *   if exclusive decrement counter
 * condition:
 *   if counter >= end goto body else goto exit
 * body:
 *   generate body
 *   decrement counter
 *   jmp condition
 * exit:
 *
 * ------------------------------------------------------------------------------ while:
 * for:
 *    generate counter
 *    counter = 0
 * condition:
 *    generate condition
 *    if condition is true goto body else goto exit
 * body:
 *    generate body
 *    increment counter
 *    jmp condition
 * exit:
 */
void generateFor(For n, GenerateState state) {
    auto forBlock       = state.createBlock("for");
    auto conditionBlock = state.createBlock("for-condition");
    auto bodyBlock      = state.createBlock("for-body");
    auto afterBodyBlock = state.createBlock("for-after-body");
    auto exitBlock      = state.createBlock("for-exit");

    n.llvmBreakBlock = exitBlock;
    n.llvmContinueBlock = afterBodyBlock;

    LLVMBuildBr(state.builder, forBlock);

    // ------------------------------------------------------------------------------ for:
    LLVMPositionBuilderAtEnd(state.builder, forBlock);

    Type counterType;
    LLVMTypeRef counterLlvmType;
    LLVMValueRef counterPtr;
    LLVMValueRef end;

    // generate counter
    if(n.hasCounter) {
        state.generate(n.counter());
        counterType     = n.counter().getType();
        counterLlvmType = state.getLLVMType(counterType);
        counterPtr      = state.lhs;
    } else {
        // Create our own counter if this is a sequence loop
        if(!n.isWhile) {
            counterType     = selectCommonType(n.start.getType(), n.end.getType());
            counterLlvmType = state.getLLVMType(counterType);
            counterPtr      = LLVMBuildAlloca(state.builder, counterLlvmType, "counter");
        }
    }

    if(n.isWhile) {
        if(n.hasCounter) {
            // counter = 0
            LLVMBuildStore(state.builder, LLVMConstNull(counterLlvmType), counterPtr);
        }
    } else {
        // generate start
        state.generate(n.start());
        state.castType(state.rhs, n.start().getType(), counterType);

        if(n.isReversed && !n.isInclusive) {
            // decrement start
            state.rhs = LLVMBuildSub(state.builder, state.rhs, LLVMConstInt(counterLlvmType, 1, 1), "decrement");
        }

        // counter = start
        LLVMBuildStore(state.builder, state.rhs, counterPtr);

        // generate end
        state.generate(n.end());
        end = state.castType(state.rhs, n.end().getType(), counterType);
    }

    LLVMBuildBr(state.builder, conditionBlock);

    // ------------------------------------------------------------------------------ condition:
    LLVMPositionBuilderAtEnd(state.builder, conditionBlock);

    LLVMValueRef counterValue;

    if(n.isWhile) {
        // generate condition
        state.generate(n.condition());

        auto zero = LLVMConstInt(state.getLLVMType(n.condition().getType()), 0, 1);
        auto cmp = LLVMBuildICmp(state.builder, LLVMIntPredicate.LLVMIntNE, state.rhs, zero, "cmp");
        LLVMBuildCondBr(state.builder, cmp, bodyBlock, exitBlock);

    } else {
        counterValue = LLVMBuildLoad2(state.builder, state.getLLVMType(counterType), counterPtr, "counter");

        LLVMIntPredicate pred;
        if(n.isReversed) {
            pred = LLVMIntPredicate.LLVMIntSGE;
        } else {
            pred = n.isInclusive ? LLVMIntPredicate.LLVMIntSLE : LLVMIntPredicate.LLVMIntSLT;
        }

        auto cmp = LLVMBuildICmp(state.builder, pred, counterValue, end, "cmp");

        LLVMBuildCondBr(state.builder, cmp, bodyBlock, exitBlock);
    }

    // ------------------------------------------------------------------------------ body:
    LLVMPositionBuilderAtEnd(state.builder, bodyBlock);

    // generate body
    foreach(b; n.bodyStatements()) {
        state.generate(b);
    }

    LLVMBuildBr(state.builder, afterBodyBlock);

    // ------------------------------------------------------------------------------ after-body:
    LLVMPositionBuilderAtEnd(state.builder, afterBodyBlock);

    // increment/decrement counter
    if(n.hasCounter) {
        if(n.isWhile) {
            counterValue = LLVMBuildLoad2(state.builder, state.getLLVMType(counterType), counterPtr, "counter");
        }
        auto add = LLVMConstInt(counterLlvmType, n.isReversed ? -1 : 1, 1);
        auto newCounter = LLVMBuildAdd(state.builder, counterValue, add, "new-counter");
        LLVMBuildStore(state.builder, newCounter, counterPtr);
    }

    LLVMBuildBr(state.builder, conditionBlock);

    // ------------------------------------------------------------------------------ exit:
    LLVMPositionBuilderAtEnd(state.builder, exitBlock);
}
