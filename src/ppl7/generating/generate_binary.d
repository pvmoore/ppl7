module ppl7.generating.generate_binary;

import ppl7.all;

void generateBinary(Binary n, GenerateState state) {

    Expression left = n.left();
    Expression right = n.right();

    Type leftType = left.getType();
    Type rightType = right.getType();
    bool isReal = n.type.isReal();

    //consoleLog("Generate Binary left:%s op:%s right:%s", n.left(), n.op, n.right());
    // ------------------------------------------------------ Left hand side
    state.generate(left);
    auto leftValue = state.rhs;
    auto assignValue = state.lhs;

    // Handle bool short circuiting
    if(n.op is Operator.BOOL_OR || n.op is Operator.BOOL_AND) {
        handleShortCircuit(n, state, leftValue);
        return;
    }

    // ------------------------------------------------------ Right hand side
    state.generate(right);
    auto rightValue = state.rhs;


    // Handle struct or array value comparison
    bool useStructOrArrayComparison = allOf(
        n.op.isOneOf(Operator.EQUAL, Operator.NOT_EQUAL),
        leftType.exactlyMatches(rightType),
        leftType.isValue(),
        leftType.isStruct() || leftType.isArray());

    if(useStructOrArrayComparison) {

        compare(leftType, n.op, assignValue, state.lhs, state, n.op == Operator.EQUAL ? "equal" : "not-equal");

        // Convert the i1 result back into an i8
        state.rhs = LLVMBuildSExt(state.builder, state.rhs, state.INT8_TYPE, "cast_to_i8");
        return;
    }


    // Convert both sides to a common type
    if(n.op.isBool()) {
        Type ty = selectCommonType(leftType, rightType);

        if(ty is null && leftType.isPointer() && rightType.isPointer()) {
            // Pointers do not have a type in LLVM. Just pick the left hand side Type here
            ty = leftType;
        }
        if(ty is null) {
            assert(ty, "Could not find a common type for %s and %s".format(leftType, rightType));
        }

        leftValue = state.castType(leftValue, leftType, ty);
        rightValue = state.castType(rightValue, rightType, ty);

        isReal = ty.isReal();

        // writefln("left  = %s (%s)", left, leftValue.printValueToString);
        // writefln("right = %s (%s)", right, rightValue.printValueToString);

    } else {
        leftValue = state.castType(leftValue, leftType, n.type);
        rightValue = state.castType(rightValue, rightType, n.type);
    }


    LLVMValueRef genCmp(LLVMRealPredicate realOp, LLVMIntPredicate intOp) {
        if(isReal) {
            return LLVMBuildFCmp(state.builder, realOp, leftValue, rightValue, stringOf(n.op).toStringz());
        }
        return LLVMBuildICmp(state.builder, intOp, leftValue, rightValue, stringOf(n.op).toStringz());
    }
    LLVMValueRef genOp(LLVMOpcode opc) {
        return LLVMBuildBinOp(state.builder, opc, leftValue, rightValue, stringOf(n.op).toStringz());
    }

    switch(n.op) {
        // Boolean operations
        case Operator.EQUAL:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOEQ, LLVMIntPredicate.LLVMIntEQ);
            break;
        case Operator.NOT_EQUAL:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealONE, LLVMIntPredicate.LLVMIntNE);
            break;
        case Operator.LT:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOLT, LLVMIntPredicate.LLVMIntSLT);
            break;
        case Operator.ULT:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOLT, LLVMIntPredicate.LLVMIntULT);
            break;
        case Operator.LTE:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOLE, LLVMIntPredicate.LLVMIntSLE);
            break;
        case Operator.ULTE:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOLE, LLVMIntPredicate.LLVMIntULE);
            break;
        case Operator.GT:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOGT, LLVMIntPredicate.LLVMIntSGT);
            break;
        case Operator.UGT:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOGT, LLVMIntPredicate.LLVMIntUGT);
            break;
        case Operator.GTE:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOGE, LLVMIntPredicate.LLVMIntSGE);
            break;
        case Operator.UGTE:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOGE, LLVMIntPredicate.LLVMIntUGE);
            break;

        // Arithmetic operations
        case Operator.ADD:
        case Operator.ADD_ASSIGN:
            state.rhs = genOp(isReal ? LLVMOpcode.LLVMFAdd : LLVMOpcode.LLVMAdd);
            break;
        case Operator.SUB:
        case Operator.SUB_ASSIGN:
            state.rhs = genOp(isReal ? LLVMOpcode.LLVMFSub : LLVMOpcode.LLVMSub);
            break;
        case Operator.MUL:
        case Operator.MUL_ASSIGN:
            state.rhs = genOp(isReal ? LLVMOpcode.LLVMFMul : LLVMOpcode.LLVMMul);
            break;
        case Operator.DIV:
        case Operator.DIV_ASSIGN:
            state.rhs = genOp(isReal ? LLVMOpcode.LLVMFDiv : LLVMOpcode.LLVMSDiv);
            break;
        case Operator.UDIV:
        case Operator.UDIV_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMUDiv);
            break;
        case Operator.MOD:
        case Operator.MOD_ASSIGN:
            state.rhs = genOp(isReal ? LLVMOpcode.LLVMFRem : LLVMOpcode.LLVMSRem);
            break;
        case Operator.UMOD:
        case Operator.UMOD_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMURem);
            break;
        case Operator.BIT_XOR:
        case Operator.BIT_XOR_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMXor);
            break;
        case Operator.BIT_AND:
        case Operator.BIT_AND_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMAnd);
            break;
        case Operator.BIT_OR:
        case Operator.BIT_OR_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMOr);
            break;
        case Operator.SHL:
        case Operator.SHL_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMShl);
            break;
        case Operator.SHR:
        case Operator.SHR_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMAShr);
            break;
        case Operator.USHR:
        case Operator.USHR_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMLShr);
            break;

        case Operator.ASSIGN:
            // Handle this at the end of the function
            break;
        default:
            assert(false, "Unexpected operator %s".format(n.op));
            break;
    }

    if(n.op.isBool()) {
        // Convert the i1 result back into an i8
        state.rhs = LLVMBuildSExt(state.builder, state.rhs, state.INT8_TYPE, "cast_to_i8");
    }

    // ------------------------------------------------------ Handle assignment
    if(n.op.isAssign()) {
        LLVMBuildStore(state.builder, state.rhs, assignValue);
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

/**
 * Handle the right hand side of a boolean and/or BinaryExpression.
 * In some cases, the result of the left hand side means we don't
 * need to evaluate the right hand side at all.
 */
void handleShortCircuit(Binary n, GenerateState state, LLVMValueRef leftValue) {
    assert(n.type.isBool(), "Expecting the Binary type to be bool (i8)");

    Type type          = n.type;
    Expression right   = n.right();
    Type rightType     = right.getType();

    bool isOr          = n.op is Operator.BOOL_OR;
    auto startBlock    = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "%s".format(n.op.stringOf()).toStringz());
    auto rhsLabel	   = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "eval_rhs");
    auto afterRhsLabel = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "after_rhs");

    LLVMBuildBr(state.builder, startBlock);

// start:
    LLVMPositionBuilderAtEnd(state.builder, startBlock);

    // convert leftValue to i1
    auto leftValueI1 = state.castToI1(leftValue);

    if(isOr) {
        // If the left hand side is true, we don't need to evaluate the right hand side
        LLVMBuildCondBr(state.builder, leftValueI1, afterRhsLabel, rhsLabel);
    } else {
        // If the left hand side is false, we don't need to evaluate the right hand side
        LLVMBuildCondBr(state.builder, leftValueI1, rhsLabel, afterRhsLabel);
    }

// eval_rhs:
    LLVMPositionBuilderAtEnd(state.builder, rhsLabel);
    state.generate(right);
    state.castType(state.rhs, rightType, type);
    auto rightValue = state.rhs;
    auto rightBlock = LLVMGetInsertBlock(state.builder);
    LLVMBuildBr(state.builder, afterRhsLabel);

// after_rhs:
    LLVMPositionBuilderAtEnd(state.builder, afterRhsLabel);

    LLVMValueRef[] phiValues      = [leftValue, rightValue];
    LLVMBasicBlockRef[] phiBlocks = [startBlock, rightBlock];

    LLVMValueRef phi = LLVMBuildPhi(state.builder, state.INT8_TYPE, "short_circuit");
    LLVMAddIncoming(phi, phiValues.ptr, phiBlocks.ptr, 2);

    state.rhs = phi;
}
/*
void handleShortCircuitAlternative(Binary n, LLVMValueRef leftValue, GenerateState state) {
    assert(n.type.isBool(), "Expecting the Binary type to be bool (i8)");

    bool isOr          = n.op is Operator.BOOL_OR;
    auto startBlock    = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "%s".format(n.op.stringOf()).toStringz());
    auto rhsLabel	   = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "eval_rhs");
    auto afterRhsLabel = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "after_rhs");

    LLVMBuildBr(state.builder, startBlock);

    // start:
    LLVMPositionBuilderAtEnd(state.builder, startBlock);

    // Ensure leftValue is i8
    leftValue = state.castType(leftValue, n.leftType(), CONST_BOOL_TYPE);

    /// create a temporary result
    auto resultVal = LLVMBuildAlloca(state.builder, state.createInt8Type(), "bool_result");
    LLVMBuildStore(state.builder, leftValue, resultVal);

    /// do we need to evaluate the right side?
    LLVMIntPredicate cmpOp = isOr ? LLVMIntPredicate.LLVMIntNE : LLVMIntPredicate.LLVMIntEQ;
    LLVMValueRef cmpResult = LLVMBuildICmp(state.builder, cmpOp, leftValue, state.constI8Bool(false), "cmp");
    LLVMBuildCondBr(state.builder, cmpResult, afterRhsLabel, rhsLabel);

// eval_rhs:
    LLVMPositionBuilderAtEnd(state.builder, rhsLabel);
    state.generate(n.right());
    state.castType(state.rhs, n.right().getType(), CONST_BOOL_TYPE);
    LLVMBuildStore(state.builder, state.rhs, resultVal);
    LLVMBuildBr(state.builder, afterRhsLabel);

// after_rhs:
    LLVMPositionBuilderAtEnd(state.builder, afterRhsLabel);
    state.rhs = LLVMBuildLoad2(state.builder, LLVMInt8TypeInContext(state.context), resultVal, "result");
}
*/

/**
 * Compare two expressions. Will return result as i1 in state.rhs
 * Assume op is either Operator.EQUAL or Operator.NOT_EQUAL
 */
void compare(Type type, Operator op,
             LLVMValueRef leftPointer, LLVMValueRef rightPointer,
             GenerateState state, string name = null) {

    if(type.isValue()) {

        // todo - handle unions later

        if(auto s = type.extract!Struct) {
            compareStructs(s, op, leftPointer, rightPointer, state, name);
            return;
        } else if(auto a = type.extract!Array) {
            compareArrays(a, op, leftPointer, rightPointer, state, name);
            return;
        }
    }

    // Compare int or real values

    auto l = LLVMBuildLoad2(state.builder, state.getLLVMType(type), leftPointer, "left");
    auto r = LLVMBuildLoad2(state.builder, state.getLLVMType(type), rightPointer, "right");

    if(type.isReal()) {
        auto llvmOp = op == Operator.EQUAL ? LLVMRealPredicate.LLVMRealOEQ : LLVMRealPredicate.LLVMRealONE;
        state.rhs = LLVMBuildFCmp(state.builder, llvmOp, l, r, "cmp");
    } else {
        auto llvmOp = op == Operator.EQUAL ? LLVMIntPredicate.LLVMIntEQ : LLVMIntPredicate.LLVMIntNE;
        state.rhs = LLVMBuildICmp(state.builder, llvmOp, l, r, "cmp");
    }
}

void compareArrays(Array array, Operator op,
                   LLVMValueRef leftPointer, LLVMValueRef rightPointer,
                   GenerateState state, string name) {
    assert(array);
    assert(array.numElements() > 0);

    Type elementType = array.elementType();
    LLVMTypeRef llvmElementType = state.getLLVMType(elementType);

    LLVMValueRef maxCount = state.createConstI32Value(array.numElements());

    auto startBlock = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "array_cmp_%s".format(name).toStringz());
    auto loopBlock = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "array_cmp_loop");
    auto cmpBlock = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "array_cmp_element");
    auto trueBlock  = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "array_cmp_true");
    auto falseBlock = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "array_cmp_false");
    auto endBlock   = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "array_cmp_phi");

    LLVMBuildBr(state.builder, startBlock);

    // start:
    LLVMPositionBuilderAtEnd(state.builder, startBlock);

    auto indexPtr = LLVMBuildAlloca(state.builder, state.INT32_TYPE, "index");
    LLVMBuildStore(state.builder, state.createConstI32Value(0), indexPtr);

    LLVMBuildBr(state.builder, loopBlock);

    // loop:
    LLVMPositionBuilderAtEnd(state.builder, loopBlock);

    // LLVMValueRef index = LLVMBuildPhi(state.builder, state.INT32_TYPE, "index");
    auto index = LLVMBuildLoad2(state.builder, state.INT32_TYPE, indexPtr, "index");

    auto loopDone = LLVMBuildICmp(state.builder, LLVMIntPredicate.LLVMIntULT, index, maxCount, "done");
    LLVMBuildCondBr(state.builder, loopDone, cmpBlock, op == Operator.EQUAL ? trueBlock : falseBlock);

    // cmp:
    LLVMPositionBuilderAtEnd(state.builder, cmpBlock);

    auto nextIndex = LLVMBuildAdd(state.builder, index, state.createConstI32Value(1), "next_index");
    LLVMBuildStore(state.builder, nextIndex, indexPtr);

    // LLVMValueRef[] indexPhiValues      = [state.createConstI32Value(0), nextIndex];
    // LLVMBasicBlockRef[] indexPhiBlocks = [startBlock, cmpBlock];
    // LLVMAddIncoming(index, indexPhiValues.ptr, indexPhiBlocks.ptr, 2);

    LLVMValueRef[] indices = [index];
    LLVMValueRef lptr = LLVMBuildInBoundsGEP2(state.builder, llvmElementType, leftPointer, indices.ptr, 1, "left-element");
    LLVMValueRef rptr = LLVMBuildInBoundsGEP2(state.builder, llvmElementType, rightPointer, indices.ptr, 1, "right-element");

    // Compare the current member for equality
    compare(elementType, Operator.EQUAL, lptr, rptr, state);
    LLVMValueRef cmp = state.rhs;

    if(op == Operator.EQUAL) {
        LLVMBuildCondBr(state.builder, cmp, loopBlock, falseBlock);
    } else {
        LLVMBuildCondBr(state.builder, cmp, loopBlock, trueBlock);
    }

    // true:
    LLVMPositionBuilderAtEnd(state.builder, trueBlock);
    LLVMBuildBr(state.builder, endBlock);

    // false:
    LLVMPositionBuilderAtEnd(state.builder, falseBlock);
    LLVMBuildBr(state.builder, endBlock);

    // phi:
    LLVMPositionBuilderAtEnd(state.builder, endBlock);

    // result
    LLVMValueRef[] phiValues      = [state.createConstI1Value(1), state.createConstI1Value(0)];
    LLVMBasicBlockRef[] phiBlocks = [trueBlock, falseBlock];

    LLVMValueRef phi = LLVMBuildPhi(state.builder, state.INT1_TYPE, "result");
    LLVMAddIncoming(phi, phiValues.ptr, phiBlocks.ptr, 2);

    state.rhs = phi;
}

/**
 * Compare two struct values.
 * Assume both sides have the same type.
 * Compare each struct member and return the result.
 */
void compareStructs(Struct struct_, Operator op,
                    LLVMValueRef leftPointer, LLVMValueRef rightPointer,
                    GenerateState state, string name) {
    assert(struct_);

    auto members            = struct_.members();
    bool equal              = op == Operator.EQUAL;
    LLVMValueRef trueValue  = state.createConstI1Value(1);
    LLVMValueRef falseValue = state.createConstI1Value(0);

    // If the struct is opaque then assume equality
    if(members.length == 0) {
        state.rhs = equal ? trueValue : falseValue;
        return;
    }

    string blockName(Variable v) {
        return "struct_cmp_%s%s".format(name ? "%s_".format(name) : "", v.name);
    }

    LLVMBasicBlockRef[] blocks = members.map!(it=>LLVMAppendBasicBlockInContext(state.context, state.currentFunction, blockName(it).toStringz())).array();

    auto trueBlock  = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "struct_cmp_true");
    auto falseBlock = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "struct_cmp_false");
    auto endBlock   = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "struct_cmp_phi");

    LLVMBuildBr(state.builder, blocks[0]);

    foreach(i, v; members) {

        LLVMPositionBuilderAtEnd(state.builder, blocks[i]);

        auto lptr = state.getStructMemberPtr(struct_.llvmType, leftPointer, i.as!int, "leftPtr");
        auto rptr = state.getStructMemberPtr(struct_.llvmType, rightPointer, i.as!int, "rightPtr");

        // Compare the current member for equality
        compare(v.getType(), Operator.EQUAL, lptr, rptr, state, v.name);
        LLVMValueRef cmp = state.rhs;

        if(equal) {
            auto nextBlock = i == members.length-1 ? trueBlock : blocks[i+1];
            LLVMBuildCondBr(state.builder, cmp, nextBlock, falseBlock);
        } else {
            auto nextBlock = i == members.length-1 ? falseBlock : blocks[i+1];
            LLVMBuildCondBr(state.builder, cmp, nextBlock, trueBlock);
        }
    }

    // true:
    LLVMPositionBuilderAtEnd(state.builder, trueBlock);
    LLVMBuildBr(state.builder, endBlock);

    // false:
    LLVMPositionBuilderAtEnd(state.builder, falseBlock);
    LLVMBuildBr(state.builder, endBlock);

    // phi:
    LLVMPositionBuilderAtEnd(state.builder, endBlock);

    // Phi node
    LLVMValueRef[] phiValues      = [trueValue, falseValue];
    LLVMBasicBlockRef[] phiBlocks = [trueBlock, falseBlock];

    LLVMValueRef phi = LLVMBuildPhi(state.builder, state.INT1_TYPE, "result");
    LLVMAddIncoming(phi, phiValues.ptr, phiBlocks.ptr, 2);

    state.rhs = phi;
}
