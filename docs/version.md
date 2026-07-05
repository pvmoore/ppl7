# Version History

## 0.2.23

- Refactor resolution
- Add more tests

## 0.2.22

- Refactor the test suite to allow more granular error testing.

## 0.2.21

- Integer number literals default to int. Cast to byte or short if required
```
int a   = 1             # ok, 1 is an int
short b = 1 as short
byte c  = 1 as byte
```

## 0.2.20

- Tidy up Lexer
- Remove EToken.TILDE_EQUAL

## 0.2.19

- [x] Remove ushr, udiv and umod.
- [x] Add new syntax for unsigned operations:
```
    - unsigned shr     >>>
    - unsigned divide  //
    - unsigned mod     %%
    - unsigned shr=    >>>=
    - unsigned div =   //=
    - unsigned mod =   %%=
    - unsigned >       |>|
    - unsigned <       |<|
    - unsigned >=      |>=|
    - unsigned <=      |<=|
```

## 0.2.18

- [x] Allow underscore in number literals eg 0b1000_0000
- [x] Change attribute syntax to [[name]] so that hash can be reused
- [x] Change line comment syntax from // to # to free up the // token for unsigned division

## 0.2.17

- Remove ABI attribute. Assume calling convention depends on the OS and not the function.
- Remove multi-statement attributes
- Add debugLibFile to CompilerOptions.Lib. Use the debug libs in debug mode and the standard libs in release mode
- Fix error CompilationError.getLocationString() when the error is in one of the library files

## 0.2.16

- Add timings which are optionally displayed after compilation
- Change builtin syntax from ::name to @name

## 0.2.15

- Rename internal @common lib to ppl. Rename @assert to ppl_assert
- Rename ArrayType to Array

## 0.2.14

- Remove parenthesis requirement from assert. Parenthesis can still be used if the expression is ambiguous.
```
// Before
assert(a is 7)

// After
assert a is 7
```
- Rename some enums
- Add property builtin function. Replaces built-in magic identifiers eg. '_ _ DEBUG _ _'
```
bool isDebug = ::property(bool, "__DEBUG__")
int myProp   = ::property(int, "myProperty", 10) // default value is 10
```

## 0.2.13

- Initial fork from stagecoach
