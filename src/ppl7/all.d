module ppl7.all;

public:

import core.sync.mutex : Mutex;

import std.stdio              : writefln, writef, writeln;
import std.format             : format;
import std.algorithm          : any, all, map, filter, find, sum;
import std.range              : array, chain;
import std.array              : join;
import std.string             : toStringz, fromStringz, replace, strip, toUpper;
import std.datetime.stopwatch : StopWatch;
import std.typecons           : Tuple, tuple;

// Import the public interface
import ppl7;

// Import the private implementation
import ppl7.Project;

import ppl7.ast.AddressOf;
import ppl7.ast.ArrayLiteral;
import ppl7.ast.As;
import ppl7.ast.Binary;
import ppl7.ast.Builtin;
import ppl7.ast.Call;
import ppl7.ast.Dot;
import ppl7.ast.EnumMember;
import ppl7.ast.Expression;
import ppl7.ast.Identifier;
import ppl7.ast.If;
import ppl7.ast.Index;
import ppl7.ast.Is;
import ppl7.ast.Number;
import ppl7.ast.Null;
import ppl7.ast.Parens;
import ppl7.ast.StringLiteral;
import ppl7.ast.StructLiteral;
import ppl7.ast.Unary;
import ppl7.ast.ValueOf;

import ppl7.ast.module_.Module;
import ppl7.ast.module_.ModuleRef;

import ppl7.ast.node.Node;
import ppl7.ast.node.NodeKind;
import ppl7.ast.node.NodeRef;

import ppl7.ast.stmts.Assert;
import ppl7.ast.stmts.Return;
import ppl7.ast.stmts.Statement;
import ppl7.ast.stmts.Variable;

import ppl7.ast.types.Alias;
import ppl7.ast.types.ArrayType;
import ppl7.ast.types.Enum;
import ppl7.ast.types.SimpleType;
import ppl7.ast.types.Function;
import ppl7.ast.types.PointerType;
import ppl7.ast.types.Struct;
import ppl7.ast.types.Type;
import ppl7.ast.types.TypeKind;
import ppl7.ast.types.TypeOf;
import ppl7.ast.types.TypeRef;

import ppl7.checking.check;
import ppl7.checking.check_function;
import ppl7.checking.check_identifier;
import ppl7.checking.check_variable;

import ppl7.errors.CompilationError;
import ppl7.errors.ErrorKind;

import ppl7.generating.generate;
import ppl7.generating.generate_array;
import ppl7.generating.generate_binary;
import ppl7.generating.generate_call;
import ppl7.generating.generate_function;
import ppl7.generating.generate_identifier;
import ppl7.generating.generate_if;
import ppl7.generating.generate_index;
import ppl7.generating.generate_module;
import ppl7.generating.generate_struct;
import ppl7.generating.generate_variable;
import ppl7.generating.GenerateState;

import ppl7.linking.link;
import ppl7.linking.lld_linker;
import ppl7.linking.ms_linker;

import ppl7.llvm.llvm_api;
import ppl7.llvm.llvm_utils;
import ppl7.llvm.llvm_target_machine;

import ppl7.parsing.attributes;
import ppl7.parsing.parse_expressions;
import ppl7.parsing.parse_statements;
import ppl7.parsing.parse_types;
import ppl7.parsing.ParseState;

import ppl7.resolving.Operator;
import ppl7.resolving.resolve_array_literal;
import ppl7.resolving.resolve_as;
import ppl7.resolving.resolve_builtin;
import ppl7.resolving.resolve_call;
import ppl7.resolving.resolve_const;
import ppl7.resolving.resolve_identifier;
import ppl7.resolving.resolve_is;
import ppl7.resolving.resolve_if;
import ppl7.resolving.resolve_number;
import ppl7.resolving.resolve_struct_literal;
import ppl7.resolving.resolve_type;
import ppl7.resolving.resolve_variable;
import ppl7.resolving.resolve;
import ppl7.resolving.ResolveState;
import ppl7.resolving.rewriter;
import ppl7.resolving.TargetOfCall;
import ppl7.resolving.TargetOfIdentifier;   

import ppl7.scanning.scanner;

import ppl7.tokenising.EToken;
import ppl7.tokenising.Lexer;
import ppl7.tokenising.Token;

import ppl7.utils.utils;
import ppl7.utils.container_utils;
import ppl7.utils.logging_utils;

__gshared { 
    // All static initialisation needs to go in here to avoid circular dependencies
    static this() {
        g_logMutex = new Mutex();
    }
    // All static destruction
    static ~this() {
        foreach(lc; g_loggingContexts.values) {
            if(lc.open) {
                lc.file.close();
            }
        }
    }
}
