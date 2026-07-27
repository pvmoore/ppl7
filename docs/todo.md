# PPL7 ToDo List

## Remove function declaration brackets if there are no parameters?

```c
fn foo {

}
```

## Remove function return type right arrow?

Current syntex:
```c
fn foo(int a) -> int
```

Possible alternatives:

```c
fn foo(int a) int
fn foo(int a; int)
fn foo(int a -> int)
```
Note: Having the type after the bracket could cause ambiguous parsing.

## Add EError codes

eg.

ARRAY_MISSING_LENGTH -> E10301

We can test for this in the test suite. This would be better because messages can be improved without
having to change a lot of tests.

## More builtins

```c
int[2] a
@elementTypeOf(a)
```

## Array properties

Add properties to arrays eg.

```c
int[3] a
int len  = a.length
int* ptr = a.ptr
```

length should be an int unless the array length > int.max when it should be a long. We know the length
at compile time.

## More constant folding

Fold Binary +/- etc for Numbers

## Allow user defined types at any scope

```c
fn foo() {
  struct A { int a }
  alias INT = int
}
```

## Remove bracket requirement from if statement?

```c
if a < 1 { x+=1 } else { y+=1 }
int a = if b < 1 { 1 } else { 3 }
```

If we do this should be enforce braces on the then and else branches?

```c
if a < 1 x+=1 else y+=1
int a = if b < 1 1 else 3
```

## C style struct literals

Convert struct literals to C style

eg.

```c
struct Z { int x, int y }
struct A { int a, Z b }
{
  .a = 1,
  .b = {
    .x = 2,
    .y = 3
  }
}
```

## Max array length

Should we introduce a maximum length for arrays? Should we allow any length for globals but limited
length for local arrays?

## Unions

Implement unions

## Imports

Currently we have imports at Module scope. We could allow these at any Statement scope but we would need
to change the way the scanner works. The Module properties would be affected:

  Module[string] importedModulesQualified;
  Module[string] importedModulesUnqualified;

Resolving identifiers, calls and TYpes would need to be modified to walk backwards up the AST.

## Public imports

Currently we only import symbols within the current Module. Any imports in external Modules are not included.
We could recursively import if the import is within a public attribute block.
We would need to account for circular imports.

## Null checks

Investigate the following functions for checking for null pointer dereferences:
```
  LLVMBuildIsNull
  LLVMBuildIsNotNull
```
Ideally we want to replace all pointer dereferances with a function call that checks the pointer is not null.
If the pointer is null we can call another function eg:
```
  @nullPointerDeref(ptr, modulename, filename, line)
```

There is already a config flag:
```
  enableNullChecks
```

## LLD Linker

Try using the LLVM linker (LLD). There is already a file created for this -> src\ppl7\linking\lld_linker.d
At the moment I am not sure which files actually implement this. Could be one of:
```
  lld64.exe
  lld-link.exe
  lld.exe
```

## Clang Linker

Add support for the Clang linker

## Debugging

Add debugging metadata

## Scope block expressions

Allow inner scope blocks to be used as expressions eg.
```c
  int a = { int b = 1; b + 1; }
```
This would yield the final expression as the result of the block. Maybe disallow return statements inside the block.

## Select expression

Add a 'select' expression that can be used like a switch but with more flexibility eg.
```c
  int a = select(t) {
    1: 10
    2: 20
    3..5: 30
    else: 100
  }

  // evaluate from top down until a condition is true and the execute the associated block

  select {
    a < 3: doSomething()
    a < 5: doSomethingElse()
    true: doThisIfNothingElseIsTrue()
  }
```

## Optional

Add an Optional type eg. int? that can be null. This would be a struct under the hood but with
some syntactic sugar to make it easier to use.
```c
  int? a = 10
  if(a?hasValue) {
    int b = a?value;
  }
```

## Auto type inference

Add auto type:
```c
  auto a = 1
```

## Loops

Implement loops.

```c
// forward
for int i, 0..<3 {}
for int i, 0..<3, 1 {}   // equivalent to above
for int i, 0..=4, 2 {}   // i += 2 after each iteration
for i, 0..<3 {}          // i is int by default
for 0..=3 {}             // variable is optional
for a..=b {}

// reversed
for int i, 3>..0, 1 {}
for int i, 4=..0, 2 {}
for i, 4=..0, n {}      // i is int by default
for i, b=..a, n {}
for long i, 0..<1000 {}
for short j, 0..<1000 {}
for byte k, 0..<1000 {}   // this is an error. the end is > 127

// while loop
for true {}
for int i, flag {}    // i in incremented per iteration
for i, flag {}        // i is int by default, incremented per iteration

for i, true  {
  if(i > 10) break
  if(i < 10) continue
}
```

Note: the variable cannot be manually initialised.

For
  [ Variable ]  // optional variable
  Expression    // start
  Expression    // end
  Expression    // step
  bool reversed
  bool inclusive

## Defer statement

```c
  defer {
    // This block is executed when the current scope exits
  }
```

## Vararg functions

We need to support functions with variable parameters for internal calls. We already support extern functions with varargs but we cannot call PPL7 functions in this way.
```c
  fn foo(int a, ... args) {
    // args is a slice of Type (requires slices)
  }
```c
  It might be better to use arrays or tuples for this eg.
```c
  fn foo(int a, int[] args) {}

  fn foo(int a, struct (int, float, bool) args) {}
```
  This still doesn't solve the problem of variable arguments of different types.

## Slices

Add slices eg. slice<int> that can be used for non-owning array views.
```c
  int[3] a = [1, 2, 3]
  slice<int> b = a[0..<2];   assert(b is [1, 2])
  slice<int> c = a[1..];     assert(c is [2, 3])
  slice<int> d = a[..1];     assert(d is [1, 2])
  slice<int> e = a[..];      assert(e is [1, 2, 3])
```

These are simple struct templates (template syntax tbc).

## Array length property

Add an array length property eg. 'a.length' that returns an int. If the array length is greater than 2^31-1 then
return a long. This length is known at compile time.

Slices should also have the same property but we won't know at compile time whether it is > 2^31-1.

## Lambdas

Decide on a syntax. Maybe one of:
```c
fn thing1(fn(int; int) a)         // single lambda param
fn thing2(int a, fn(int; int) b)  // two params, lambda param at the end

// simple explicit
thing1(fn(int a) { return 1 })
thing2(3, fn(int a) { return 1 })

thing1((a){ return 1})
thing2(3, (a){ return 1})
```

## Function and function ptr syntax

Change function syntax to one of:
```c
fn name(int a, int b; int)  // move the return type inside the parenthesis
fn name(int a, int b -> int)
fn name(int a, int b) int   // just remove '->'
```
