# Version History

## 0.2.14

- Rename some enums
- Add property builtin function. Replaces built-in magic identifiers eg. '_ _ DEBUG _ _'
```
bool isDebug = ::property(bool, "__DEBUG__")
int myProp = ::property(int, "myProperty", 10) // default value is 10
```

## 0.2.13

- Initial fork from stagecoach
