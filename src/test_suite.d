module test_suite;

import std.path;
import std.stdio     : writef, writefln;
import std.file      : read, dirEntries, SpanMode, exists, remove;
import std.array     : replace, join;
import std.string    : indexOf, split, strip, toLower;
import std.format    : format;
import std.algorithm : map;
import std.range     : array;
import std.datetime.stopwatch : StopWatch, AutoStart;

import ppl7;

__gshared {
    uint g_testIndex;
    uint g_numPassed;
    uint g_numFailed;

    bool g_verboseFailures = true;  // enable to dump errors for all failed tests

    bool g_compileInDebugMode = true; // tests will be compiled in debug mode

    string[] g_tagsToRun; // = ["pete"];
}

void runTestSuite() {
    writefln("");

    if(g_tagsToRun.length > 0) {
        writefln("%sTags: %s%s\n", YELLOW_BOLD, g_tagsToRun, RESET);
    }

    StopWatch watch = StopWatch(AutoStart.yes);
    auto start = watch.peek().total!"nsecs";

    foreach(e; dirEntries("test_suite", SpanMode.shallow)) {
        if(e.isDir) {
            string directory = e.name.buildNormalizedPath().replace("\\", "/");
            runTestDirectory(e, directory);
        }
    }

    auto end = watch.peek().total!"nsecs";

    writef("%s passed, %s failed ", g_numPassed, g_numFailed);

    if(g_numFailed > 0) {
        writefln("%s[FAIL]%s", RED_BOLD, RESET);
    } else {
        writefln("%s[PASS]%s", GREEN_BOLD, RESET);
    }
    writefln("\n%.2f ms", (end-start) / 1_000_000.0);
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

enum {
    BLUE_BOLD     = "\u001b[34;1m",
    CYAN          = "\u001b[36m",
    GREEN_BOLD    = "\u001b[32;1m",
    RED_BOLD      = "\u001b[31;1m",
    MAGENTA_BOLD  = "\u001b[35;1m",
    YELLOW_BOLD   = "\u001b[33;1m",
    WHITE_BOLD    = "\u001b[37;1m",
    RESET         = "\u001b[0m",
}

void runTestDirectory(string suiteName, string directory) {
    writefln("[%s%s%s]", WHITE_BOLD, suiteName, RESET);
    foreach(e; dirEntries(directory, "**.p7", SpanMode.breadth)) {
        runTest(e.name);
    }
    writefln("");
}

void runTest(string filename) {
    filename = filename.buildNormalizedPath().replace("\\", "/");

    // Read the test file and extract the test metadata
    Meta meta = Meta.readFrom(filename);
    if(!meta.isTest) return;

    if(meta.args.length > 0) {
        throw new Exception("Implement test suite args");
    }

    // Filter by tags
    if(g_tagsToRun.length > 0) {
        if(!meta.containsAllTags(g_tagsToRun)) {
            return;
        }
    }

    auto options = new CompilerOptions();
    options.writeLL     = true;
    options.writeAST    = true;
    options.writeObj    = false;
    options.checkOnly   = false;
    options.cleanTarget = false;

    options.subsystem = "console";
    options.targetDirectory = ".target/";
    options.targetName = "test";

    options.verboseLogging = false;

    options.isDebug = g_compileInDebugMode;

    // Assume these will all be enabled to ensure valid tests fail on runtime error
    options.enableAsserts       = true;
    options.enableNullChecks    = true;
    options.enableBoundsChecks  = true;

    options.properties["myBoolean"] = "true";
    options.properties["myInteger"] = "3";
    options.properties["myFloat"]   = "3.14";

    if(exists(".target/test.exe")) {
        remove(".target/test.exe");
    }

    Compiler compiler = new Compiler(options);

    auto errors = compiler.compileProject(filename);

    bool pass = false;
    string[] msg;

    if(meta.errors.length == 0) {
        // This is expected to pass. If there are no errors (in which case this is a fail) then
        // we need to run the executable to check the status code

        if(errors.length == 0) {
            // This is a pass if the return code is 0
            pass = runCode();
        } else if(g_verboseFailures) {
            // Dump the errors
            foreach(e; errors) {
                writefln("%s", e.getPrettyString());
            }
        }
    } else {
        // This is expected to fail. Check that all expected errors are found

        int numFound;
        foreach(actual; errors) {
            string summary = actual.getSummary().toLower();
            foreach(expected; meta.errors) {
                if(summary.indexOf(expected) != -1) {
                    numFound++;
                }
            }
        }
        pass = numFound == meta.errors.length;

        if(!pass) {
            msg ~=  "Not all expected error(s) were found:";
            msg ~= meta.errors.map!(it=>"  Expected : '%s'".format(it)).array();
            msg ~= errors.map!(it=>"  Actual   : '%s'".format(it.getSummary())).array();

            if(errors.length == 0) {
                msg ~= "  Actual   : No errors found";
            }
        }
    }

    writef("[%s] %s'%s' %s %s", g_testIndex, CYAN, meta.name, filename, RESET);

    if(pass) {
        g_numPassed++;
        writefln(" %s%s%s", GREEN_BOLD, "PASS", RESET);
    } else {
        g_numFailed++;
        writefln(" %s%s%s", RED_BOLD, "FAIL", RESET);
        if(msg) {
            foreach(m; msg) writefln("  %s%s%s", YELLOW_BOLD, m, RESET);
        }
    }
    g_testIndex++;
}

bool runCode() {
    import std.process : execute;

    int returnStatus;
    try{
        auto result = execute([".target/test.exe"]);

        returnStatus = result.status;
        if(returnStatus != 0) {
            writefln("status = %s", returnStatus);
            writefln("output = '%s'", result.output.strip());
        }

    }catch(Exception e) {
        returnStatus = -1;
        writefln("error = %s", e.msg);
    }

    return returnStatus==0;
}

struct Meta {
    bool isTest;
    string name;
    string[] tags;
    string[] args;
    string[] errors;

    bool containsAllTags(string[] requiredTags) {
        foreach(t; requiredTags) {
            foreach(t2; tags) {
                if(t == t2) return true;
            }
        }
        return false;
    }

    /**
     * magic!!
     * name "01_basic_variables"
     * tags [ variables, locals, globals ]
     * args []
     * errors []
     */
    static Meta readFrom(string filename) {
        string s = cast(string)read(filename);

        // Skip if this is not a test suite main file
        if(s.indexOf("magic!!") == -1) {
            return Meta();
        }

        s = between(s, null, "/*", "*/");

        Meta meta = {
            isTest: true
        };
        meta.name   = between(s, "name", "\"", "\"");
        meta.tags   = between(s, "tags", "[", "]").split(",").map!(it=>it.strip()).array();
        meta.args   = between(s, "args", "[", "]").split(",").map!(it=>it.strip()).array();
        meta.errors = between(s, "errors", "[", "]")
            .split(",")
            .map!(it=>it.strip())
            .map!(it=>it.toLower())
            .map!((it)=>(it.length > 0 && it[0] == '"') ? it[1..$-1] : it)
            .array();

        return meta;
    }
    string toString() {
        return ("Meta {\n" ~
            "  name \"%s\"\n" ~
            "  tags %s\n" ~
            "  args %s\n" ~
            "  errors %s\n}"
        ).format(name, tags, args, errors);
    }
private:
    static string between(string s, string skipTo, string start, string end) {
        auto fromIdx  = skipTo is null ? 0 : s.indexOf(skipTo) + skipTo.length;
        auto startIdx = s.indexOf(start, fromIdx) + start.length;
        auto endIdx   = s.indexOf(end, startIdx);
        return s[startIdx..endIdx];
    }
}
