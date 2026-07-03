module ppl7.source_provider;

import ppl7.all;

interface ISourceProvider {
    bool sourceAvailable(string filename);
    string getSource(string filename);
}

class FileSourceProvider : ISourceProvider {
    import std.file : read, exists;

    override bool sourceAvailable(string filename) {
        return exists(filename);
    }
    override string getSource(string filename) {
        return cast(string)read(filename);
    }
}
