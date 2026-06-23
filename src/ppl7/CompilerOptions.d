module ppl7.CompilerOptions;

import ppl7.all;

final class CompilerOptions {
public:
    struct Lib {
        string name;                // eg. "core"
        string sourceDirectory;     // eg. "C:/work/ppl7/libs/core"
        string libFile;             // eg. "C:/work/ppl7/libs/core/lib/libcore.lib" 
    }
    enum TargetType {
        EXE,
        LIB
    }

    TargetType targetType  = TargetType.EXE;
    string targetDirectory = ".target/";
    string targetTriple    = "x86_64-pc-windows-msvc";
    string targetName;      // if this is empty then use the base name of the main file
    string subsystem       = "console";

    bool verboseLogging = false;
    bool isDebug        = true;
    bool checkOnly      = false;
    uint maxErrors      = uint.max;

    bool enableAsserts      = true;
    bool enableNullChecks   = true; 
    bool enableBoundsChecks = true;

    bool writeObj   = false;
    bool writeLL    = false;
    bool writeAST   = false;

    this() {
        // Add built-in libraries
        CompilerOptions.Lib coreLib = {
            name: "core",
            sourceDirectory: "libs/core",
            libFile: null
        };

        CompilerOptions.Lib commonLib = {
            name: "@common",
            sourceDirectory: "libs/common",
            libFile: null
        };

        addLib(coreLib);
        addLib(commonLib);
    }

    Lib[] getLibs() { return libs; }

    Lib* getLib(string name) {
        foreach(i, lib; libs) if(lib.name == name) return &libs[i];
        return null;
    }

    void addLib(Lib lib) {
        if(auto prevLib = getLib(lib.name)) {
            throw new Exception("Library '%s' already defined".format(lib.name));
        }

        if(lib.sourceDirectory) {
            lib.sourceDirectory = toCanonicalDirectory(lib.sourceDirectory, false);
        }

        libs ~= lib;
    }

    override string toString() {
        return ("CompilerOptions {\n" ~
            "  targetTriple: %s\n" ~
            "  subsystem: %s\n" ~
            "  isDebug: %s\n" ~
            "  checkOnly: %s\n" ~
            "  enableAsserts: %s\n" ~
            "  enableNullChecks: %s\n" ~
            "  enableBoundsChecks: %s\n" ~
            "  writeObj: %s\n" ~
            "  writeLL: %s\n" ~
            "  writeAST: %s\n" ~
            "  libs: %s\n" ~
            "}").format(
                targetTriple, 
                subsystem, 
                isDebug, 
                checkOnly, 
                enableAsserts, 
                enableNullChecks, 
                enableBoundsChecks, 
                writeObj, 
                writeLL, 
                writeAST,
                libs); 
    }
//──────────────────────────────────────────────────────────────────────────────────────────────────
private:
    Lib[] libs;
}
