module ppl7.errors.CompilationError;

import ppl7.all;
import ppl7.errors.error_utils;
import ppl7.errors.error_summary;
import ppl7.errors.error_extra_info;

interface ErrorMetadata {}

final class StringErrorMetadata : ErrorMetadata { string msg; this(string msg) { this.msg = msg; } }

final class VariableErrorMetadata : ErrorMetadata {
    Variable[] duplicateVariables;
    this(Variable[] dupes) {
        this.duplicateVariables = dupes;
    }
}

class CompilationError {
public:
    this(Module mod, Statement stmt, int line, int column, EError kind, ErrorMetadata extraInfo) {
        this.mod = mod;
        this.stmt = stmt;
        this.line = line;
        this.column = column;
        this._eerror = kind;
        this.extraInfo = extraInfo;
    }
    EError eerror() {
        return _eerror;
    }
    string getLocationString() {
        return "%s%s(%s,%s)".format(mod.baseDirectory, mod.relFilename, line+1, column+1);
    }
    string getSummary() {
        return getSummaryMessage(this);
    }
    string getPrettyString() {
        return formatErrorMessage(mod, getSummaryMessage(this), line, column);
    }
    string getExtraInfo() {
        return getExtraInfoMessage(this);
    }
    override bool opEquals(Object o) {
        if(CompilationError e = o.as!CompilationError) {
            return this._eerror == e._eerror && this.stmt is e.stmt;
        }
        return false;
    }
package:
    int line;
    int column;
    Statement stmt;
    EError _eerror;
    Module mod;
    ErrorMetadata extraInfo;
}

void warn(ParseState state, string msg) {
    consoleLog(ansiWrap("[%s:%s] Warning: %s".format(state.mod.relFilename, state.line()+1, msg), Ansi.YELLOW));
}
void warn(Statement n, string msg) {
    consoleLog(ansiWrap("[%s:%s] Warning: %s".format(n.getModule().relFilename, n.startToken.line+1, msg), Ansi.YELLOW));
}

void syntaxError(Module mod, int line, int column, string msg) {
    mod.project.addError(new CompilationError(mod, null, line, column, EError.SYNTAX, new StringErrorMetadata(msg)));
}
void syntaxError(ParseState state, string msg) {
    Token t = state.token();
    state.project.addError(new CompilationError(state.mod, null, t.line, t.column, EError.SYNTAX, new StringErrorMetadata(msg)));
}
void syntaxError(ParseState state, int offset, string msg) {
    Token t = state.peek(offset);
    state.project.addError(new CompilationError(state.mod, null, t.line, t.column, EError.SYNTAX, new StringErrorMetadata(msg)));
}
void syntaxError(Module mod, Token token, string msg) {
    mod.project.addError(new CompilationError(mod, null, token.line, token.column, EError.SYNTAX, new StringErrorMetadata(msg)));
}

void resolutionError(Node n, EError kind, ErrorMetadata extraInfo = null) {
    Token t = n.as!Statement.startToken;
    n.getProject().addError(new CompilationError(n.getModule(), n.as!Statement, t.line, t.column, kind, extraInfo));
}



void semanticError(Node n, EError kind, ErrorMetadata extraInfo = null) {
    semanticError(n.getProject(), n.getModule(), n, kind, extraInfo);
}
void semanticError(Statement n, int offset, EError kind, ErrorMetadata extraInfo = null) {
    Module mod = n.getModule(); assert(mod);
    Token t = mod.getToken(n.tokenIndex + offset);
    mod.project.addError(new CompilationError(mod, n, t.line, t.column, kind, extraInfo));
}
void semanticError(Project project, Module mod, Node n, EError kind, ErrorMetadata extraInfo = null) {
    Token t;
    auto stmt = n.as!Statement;
    if(stmt) {
        t = mod.tokens[stmt.tokenIndex];
    }
    project.addError(new CompilationError(mod, stmt, t.line, t.column, kind, extraInfo));
}
void semanticError(ParseState state, Statement stmt, EError kind, ErrorMetadata extraInfo = null) {
    semanticError(state.project, state.mod, stmt, kind, extraInfo);
}
