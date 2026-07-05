module ppl7.CompilerOptions;

import ppl7.all;

final class CompilerOptions {
public:
    struct Lib {
        string name;                // eg. "core"
        string sourceDirectory;     // eg. "C:/work/ppl7/libs/core"
        string libFile;             // eg. "C:/work/ppl7/libs/core/lib/libcore.lib"
        string debugLibFile;        // eg. "C:/work/ppl7/libs/core/lib/libcore.lib"
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

    bool enableTimings  = false;
    bool writeObj       = false;
    bool writeLL        = false;
    bool writeAST       = false;
    bool cleanTarget    = false;    // Remove existing files in the target directory

    // built-in properties and properties passed in by the user
    // eg. -Dmy_property=1
    string[string] properties;

    ISourceProvider sourceProvider;

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
//──────────────────────────────────────────────────────────────────────────────────────────────────
package:
    void prepareForUse() {
        // Create the default source provider if none was provided
        if(!sourceProvider) {
            sourceProvider = new FileSourceProvider();
        }

        // Add built-in properties
        properties["__BOUNDS_CHECKS__"] = "%s".format(enableBoundsChecks);
        properties["__DEBUG__"]         = "%s".format(isDebug);
        properties["__ASSERTS__"]       = "%s".format(enableAsserts);
        properties["__NULL_CHECKS__"]   = "%s".format(enableNullChecks);

        // Add built-in libraries
        CompilerOptions.Lib coreLib = {
            name: "core",
            sourceDirectory: "libs/core",
            libFile: null,
            debugLibFile: null
        };

        CompilerOptions.Lib commonLib = {
            name: "ppl",
            sourceDirectory: "libs/ppl",
            libFile: null,
            debugLibFile: null
        };

        addLib(coreLib);
        addLib(commonLib);
    }
//──────────────────────────────────────────────────────────────────────────────────────────────────
private:
    Lib[] libs;
}
