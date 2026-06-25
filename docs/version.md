# Version History

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
