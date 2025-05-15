module mc.log;

import std.algorithm : map;
import std.array : Appender;
import std.ascii : newline;
import std.format : format, formattedWrite;
import std.stdio : File, stdout;

import mc.config : Config;
import mc.util.ansi_color : AnsiColor;

@safe:

struct LogLevel
{
    enum fatal      = LogLevel(0, AnsiColor.reset.bg.red.light.bold, "[FATAL] %s");
    enum critical   = LogLevel(1, AnsiColor.reset.bg.red.bold, "[CRIT] %s");
    enum error      = LogLevel(2, AnsiColor.reset.fg.red.bold, "[ERROR] %s");
    enum warning    = LogLevel(3, AnsiColor.reset.fg.yellow, "[WARN] %s");
    enum info       = LogLevel(4, AnsiColor.reset.fg.green, "[INFO] %s");
    enum diagnostic = LogLevel(5, "[DIAG] %s");
    enum debug_     = LogLevel(6, AnsiColor.reset.fg.light, "[DEBUG] %s");
    enum trace      = LogLevel(7, AnsiColor.reset.fg.light.italic, "[TRACE] %s");

    private
    {
        uint m_level;
        string m_fmt;
    }

scope:
pure:
    private nothrow
    this(FmtParts...)(in uint level, in FmtParts fmtParts)
    {
        m_level = level;
        m_fmt = {
            Appender!string a;
            foreach (fmt; fmtParts)
                a ~= fmt;
            a ~= AnsiColor.reset.toString;
            a ~= newline;
            return a[];
        }();
    }
}

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
        => Logger(module_);

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
        if (ct_level.m_level <= Config.ct_logLevel.m_level)
        {
            enum string ct_combinedFmt = ct_level.m_fmt
                .format("%s: %s")
                .format("%s", ct_fmt);

            trustedStdout
                .lockingTextWriter
                .formattedWrite!ct_combinedFmt(m_id, args);
        }
    }

    void trace   (string fmt, Args...)(lazy Args args) const => log!(LogLevel.trace,      fmt, Args)(args);
    void dbg     (string fmt, Args...)(lazy Args args) const => log!(LogLevel.debug_,     fmt, Args)(args);
    void diag    (string fmt, Args...)(lazy Args args) const => log!(LogLevel.diagnostic, fmt, Args)(args);
    void info    (string fmt, Args...)(lazy Args args) const => log!(LogLevel.info,       fmt, Args)(args);
    void warn    (string fmt, Args...)(lazy Args args) const => log!(LogLevel.warning,    fmt, Args)(args);
    void error   (string fmt, Args...)(lazy Args args) const => log!(LogLevel.error,      fmt, Args)(args);
    void critical(string fmt, Args...)(lazy Args args) const => log!(LogLevel.critical,   fmt, Args)(args);
    void fatal   (string fmt, Args...)(lazy Args args) const => log!(LogLevel.fatal,      fmt, Args)(args);
}
