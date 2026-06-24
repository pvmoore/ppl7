module ppl7.utils.utils;

import ppl7.all;

/**
 * Convert relative filename to canonical Module name.
 * Assumes relFilename is relative to the project directory
 * Assumes the filename path separator is '/' 
 */
string toModuleName(string relFilename) {
    import std.path : extension;
    string ext = extension(relFilename);
    assert(ext);
    return relFilename[0..$-ext.length];
}
string toSourceFilename(string moduleName) {
    return moduleName ~ ".p7";
}

/**
 * Convert a path to a canonical form.
 *  - If forceToAbsolute is true then the path is converted to an absolute path.
 *  - The path separator is normalised to '/'.
 *  - A trailing '/' is added.
 */
string toCanonicalDirectory(string path, bool forceToAbsolute) {
    import std.path : buildNormalizedPath, absolutePath;
    import std.array : replace;

    string p1 = forceToAbsolute ? absolutePath(path) : path;
    string p2 = buildNormalizedPath(p1).replace("\\", "/");
    if(!p2.endsWith("/")) p2 ~= "/"; 
    return p2;
}

/**
 * Convert a path to a canonical form.
 *  - If forceToAbsolute is true then the path is converted to an absolute path.
 *  - The path separator is normalised to '/'.
 */
string toCanonicalFilename(string path, bool forceToAbsolute) {
    import std.path : buildNormalizedPath, absolutePath;
    import std.array : replace;

    string p1 = forceToAbsolute ? absolutePath(path) : path;
    return buildNormalizedPath(p1).replace("\\", "/");
}

void writeModuleLL(Project project, Module mod) {
    string filename = project.getTargetFilename(mod, "", "_opt", "ll");
    writeLLToFile(mod, filename);
}
void writeModuleAST(Project project, Module mod, string suffix = "") {
    string filename = project.getTargetFilename(mod, "ast", suffix, "ast");

    import std.stdio : File;
    auto f = File(filename, "w");
    scope(exit) f.close();
    f.write(mod.dump());
}
void writeAllModulesAST(Project project, string suffix) {
    foreach(mod; project.allModules) {
        writeModuleAST(project, mod, suffix);
    }
}
void writeScanResults(Project project, Module mod) {
    string filename = project.getTargetFilename(mod, "scan", "", "txt");
    import std.file : write;
    write(filename, mod.scanResult.toString());
}

bool isDigit(char c) {
    return c >= '0' && c <= '9';
}
bool isBool(string s) {
    string b = s.toLower();
    return b == "true" || b == "false";
}
bool isNumber(string s) {
    if(s is null || s.length == 0) return false;
    int pos = s[0] == '-' ? 1 : 0;
    foreach(c; s[pos..$]) if(!isDigit(c)) return false;
    return true;
}

bool toBool(string s) {
    string b = s.toLower();
    return b == "true" || (isNumber(b) && toInt(b) != 0);
}
long toLong(string s) {
    import std.conv : to;
    return to!long(s);
}
int toInt(string s) {
    import std.conv : to;
    return to!int(s);
}
float toFloat(string s) {
    import std.conv : to;
    return to!float(s);
}
double toDouble(string s) {
    import std.conv : to;
    return to!double(s);
}

/**
 * Return a 'n' times repeated string
 */
string repeatStr(string s, ulong n) {
    char[] result;
    result.reserve(n * s.length);
    foreach(i; 0..n) result ~= s;
    return result.as!string;
}

// ------------------------------------------------------------- Useful template functions

template isObject(T) {
    const bool isObject = is(T==class) || is(T==interface);
}

void throwIf(A...)(bool result, string msgFmt, A args) {
    if(result) throw new Exception(format(msgFmt, args));
}

void todo(A...)(string msgFmt, A args) {
    throwIf(true, "todo: " ~ format(msgFmt, args));
}

T minOf(T)(T a, T b) {
    return a < b ? a : b;
}
T maxOf(T)(T a, T b) {
    return a > b ? a : b;
}

bool isOneOf(T)(T thing, T[] args...) {
    foreach(a; args) if(a==thing) return true;
    return false;
}

T as(T,I)(I o) { return cast(T)o; }

bool isA(T,I)(I o) if(isObject!T && isObject!I) { return cast(T)o !is null; }



