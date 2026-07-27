module test_suite;

import std.path;
import std.stdio     : writef, writefln;
import std.file      : read, dirEntries, SpanMode, exists, remove;
import std.array     : replace, join;
import std.string    : indexOf, split, strip, toLower;
import std.format    : format;
import std.algorithm : map, uniq;
import std.range     : array, chain;
import std.traits    : isSomeString;
import std.datetime.stopwatch : StopWatch, AutoStart;
import std.regex     : Regex, regex, matchFirst;

import ppl7.all;

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
        runTestFile(e.name);
    }
    writefln("");
}

struct Variation {
    string name;
    string src;
    Regex!char[] errorRegexes;
    bool moreToCome;
}

void runTestFile(string filename) {
    filename = filename.buildNormalizedPath().replace("\\", "/");

    Tuple!(string, "name", Regex!char, "error") getNameAndErrorString(string line) {
        auto q1 = line.indexOf("\"");        assert(q1!=-1);
        auto q2 = line.indexOf("\"", q1+1);  assert(q2!=-1);

        string error = ".*" ~ line[q2+1..$-1].strip() ~ ".*";

        return tuple!("name", "error")(line[q1+1..q2], regex(error));
    }

    // Split the source file if it contains #begin and #end blocks
    Variation[] getSourceVariations() {
        string original = readSource(filename, true);
        Variation[] variations;

        Variation getVariation(int variation) {
            bool found = variation == 0;
            long pos = original.indexOf("#error");
            if(pos == -1) {
                return Variation(null, found ? original : null);
            }
            Variation var;
            int section = -1;
            char[] s = original.dup;

            while(true) {
                section++;

                auto start = s.indexOf("#error", pos); if(start == -1) break;
                auto end   = s.indexOf("#end", start); if(end == -1) break;

                end += 4;

                // This variation is the one we want
                if(section == variation) {
                    var.moreToCome = true;
                    pos = start+6;
                    auto line = s[pos..s.indexOf("\n", pos)];

                    auto t = getNameAndErrorString(line.as!string);
                    var.name = t.name;
                    var.errorRegexes = [t.error];

                    pos = end;
                    continue;
                }

                // Blank out this unwanted section
                foreach(n; start..end) {
                    if(s[n] != '\n' && s[n] != '\r') {
                        s[n] = ' ';
                    }
                }
            }
            var.src = cast(string)s;
            return var;
        }

        int v;
        while(true) {
            auto var = getVariation(v++);
            variations ~= var;
            if(!var.moreToCome) break;
        }

        return variations;
    }

    auto sourceProvider = new class ISourceProvider {
        string src;
        override bool sourceAvailable(string filename) {
            return exists(filename);
        }
        override string getSource(string fn) {
            if(fn == filename) return src;
            return cast(string)read(fn);
        }
    };

    auto variations = getSourceVariations();
    foreach(i, v; variations) {
        sourceProvider.src = v.src;
        runTest(filename, sourceProvider, v);
    }
}
void runTest(string filename, ISourceProvider sourceProvider, Variation variation) {

    string contents = cast(string)read(filename);

    // Read the test file and extract the test metadata
    Meta meta = Meta.readFromString(contents);
    if(!meta.isTest) return;

    meta.errorRegexes = variation.errorRegexes;

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

    options.sourceProvider = sourceProvider;

    if(exists(".target/test.exe")) {
        remove(".target/test.exe");
    }

    Compiler compiler = new Compiler(options);

    auto errors = compiler.compileProject(filename);

    bool pass = false;
    string[] msg;

    if(meta.errorRegexes.length == 0) {
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
        // This is expected to fail. Check that all expected error is found
        foreach(actual; errors) {

            string summary = actual.getSummary();//.toLower();

            auto c = matchFirst(summary, meta.errorRegexes[0]);
            if(!c.empty) {
                pass = true;
                break;
            }

            // if(summary.indexOf(meta.error) != -1) {
            //     pass = true;
            //     break;
            // }
        }

        if(!pass) {
            msg ~=  "Expected error was not found:";
            msg ~= "  Expected : '%s'".format(meta.errorRegexes[0]);
            msg ~= errors.map!(it=>"  Actual   : '%s'".format(it.getSummary())).array();

            if(errors.length == 0) {
                msg ~= "  Actual   : No errors found";
            }
        }
    }

    string variationNameStr = variation.name ? "(%s)".format(variation.name) : "";

    writef("[%s] %s'%s' %s %s%s", g_testIndex, CYAN, meta.name, filename, variationNameStr, RESET);

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
    Regex!char[] errorRegexes;

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
     */
    static Meta readFromString(string s) {

        // Skip if this is not a test suite main file
        if(s.indexOf("magic!!") == -1) {
            return Meta();
        }

        s = getBetween(s, null, "/*", "*/");

        Meta meta = {
            isTest: true
        };
        meta.name   = getBetween(s, "name", "\"", "\"");
        meta.tags   = getBetween(s, "tags", "[", "]").split(",").map!(it=>it.strip()).array();
        meta.args   = getBetween(s, "args", "[", "]").split(",").map!(it=>it.strip()).array();

        return meta;
    }
    string toString() {
        return ("Meta {\n" ~
            "  name \"%s\"\n" ~
            "  tags %s\n" ~
            "  args %s\n" ~
            "  error %s\n}"
        ).format(name, tags, args, errorRegexes);
    }
}

string getBetween(T)(T s, string skipTo, string start, string end) if(isSomeString!T) {
    auto fromIdx  = skipTo is null ? 0 : s.indexOf(skipTo) + skipTo.length;
    auto startIdx = s.indexOf(start, fromIdx); if(startIdx == -1) return null;
    startIdx += start.length;
    auto endIdx   = s.indexOf(end, startIdx); if(endIdx == -1) return null;
    return cast(string)s[startIdx..endIdx];
}

string readSource(string filename, bool stripMultilineComments) {
    char[] s = cast(char[])read(filename);
    if(stripMultilineComments) {
        int pos;

        int peek(int offset) {
            if(pos+offset >= s.length) return 0;
            return s[pos+offset];
        }

        while(pos < s.length) {
            if(peek(0) == '/' && peek(1) == '*') {
                // Start of a multi-line comment

                s[pos]   = ' ';
                s[pos+1] = ' ';
                pos += 2;

                while(pos < s.length) {

                    if(peek(0) == '*' && peek(1) == '/') {
                        // End of a multi-line comment

                        s[pos]   = ' ';
                        s[pos+1] = ' ';
                        pos += 2;
                        break;
                    } else {
                        if(peek(0) == '\n') {

                        } else {
                            s[pos] = ' ';
                        }
                        pos++;
                    }
                }
            } else pos++;
        }
    }
    return cast(string)s;
}
