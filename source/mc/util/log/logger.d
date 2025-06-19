module mc.util.log.logger;

import std.algorithm : map;
import std.array : Appender, join, split;
import std.exception : assumeWontThrow;
import std.format : format, formattedWrite;
import std.stdio : File, stdout;
import std.string : lastIndexOf;

import mc.config : Config;
import mc.util.log.log_level : LogLevel;

// TODO: support chain of const parent scopes, scopes emit a static or dynamic string

@safe:

private @trusted nothrow @nogc
ref File trustedStdout()
    => stdout;

struct Logger
{
    private
    {
        string m_id = "Unspecified";
    }

scope:
    invariant
    {
        assert(m_id.length);
    }

    static pure nothrow @nogc
    Logger moduleLogger(in string module_ = __MODULE__)
        => Logger(id: module_);

    static pure nothrow
    Logger packageLogger(in string module_ = __MODULE__)
    {
        const lastIndex = module_.lastIndexOf(".").assumeWontThrow;
        if (lastIndex >= 0)
            return Logger(id: module_[0 .. lastIndex]);
        else
            return Logger(id: module_);
    }

    pure nothrow @nogc
    this(in string id)
    in (id.length)
    {
        m_id = id;
    }

    pure nothrow
    Logger derive(in string id) const
        => Logger(m_id ~ ": " ~ id);

    void log(LogLevel ct_level, string ct_fmt, Args...)(lazy Args args) const
    {
        if (ct_level <= Config.ct_logLevel)
        {
            enum string ct_combinedFmt = ct_level.getFmt
                .format("%s: %s")
                .format("%s", ct_fmt);

            trustedStdout
                .lockingTextWriter
                .formattedWrite!ct_combinedFmt(m_id, args);
        }
    }

    void fatal   (string fmt, Args...)(lazy Args args) const => log!(LogLevel.fatal,      fmt, Args)(args);
    void critical(string fmt, Args...)(lazy Args args) const => log!(LogLevel.critical,   fmt, Args)(args);
    void error   (string fmt, Args...)(lazy Args args) const => log!(LogLevel.error,      fmt, Args)(args);
    void warn    (string fmt, Args...)(lazy Args args) const => log!(LogLevel.warning,    fmt, Args)(args);
    void info    (string fmt, Args...)(lazy Args args) const => log!(LogLevel.info,       fmt, Args)(args);
    void diag    (string fmt, Args...)(lazy Args args) const => log!(LogLevel.diagnostic, fmt, Args)(args);
    void dbg     (string fmt, Args...)(lazy Args args) const => log!(LogLevel.debug_,     fmt, Args)(args);
    void trace   (string fmt, Args...)(lazy Args args) const => log!(LogLevel.trace,      fmt, Args)(args);
}
