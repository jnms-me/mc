module mc.log;

import std.algorithm : map;
import std.array : Appender;
import std.format : f = format;
import std.stdio : writef, writefln;

import mc.config : Config;
import mc.util.ansi_color : AnsiColor;

@safe:

struct LogLevel
{
    enum trace      = LogLevel(0, AnsiColor.reset.fg.light.italic, "[TRACE] %s");
    enum debug_     = LogLevel(1, AnsiColor.reset.fg.light, "[DEBUG] %s");
    enum diagnostic = LogLevel(2, "[DIAG] %s");
    enum info       = LogLevel(3, AnsiColor.reset.fg.green, "[INFO] %s");
    enum warning    = LogLevel(4, AnsiColor.reset.fg.yellow, "[WARN] %s");
    enum error      = LogLevel(5, AnsiColor.reset.fg.red.bold, "[ERROR] %s");
    enum critical   = LogLevel(6, AnsiColor.reset.bg.red.bold, "[CRIT] %s");
    enum fatal      = LogLevel(7, AnsiColor.reset.bg.red.light.bold, "[FATAL] %s");

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
            return a[];
        }();
    }
}

struct Logger
{
    private
    {
        string m_id = "Unspecified";
    }

    static pure nothrow @nogc
    Logger moduleLogger(in string module_ = __MODULE__)
        => Logger(module_);

scope:
    pure nothrow @nogc
    this(in string id)
    in (id.length)
    {
        m_id = id;
    }

    pure nothrow
    Logger derive(in string id) const
        => Logger(m_id ~ ": " ~ id);

    void log(LogLevel level, string fmt, Args...)(lazy Args args) const
    {
        static if (level.m_level >= Config.ct_logLevel.m_level)
        {
            try
            {
                // TODO: split writing and formatting to differentiate lazy args eval exceptions from log exceptions
                try
                    writefln!(level.m_fmt)(f!"%s: %s"(m_id, f!fmt(args)));
                catch (Exception e)
                {
                    writefln!"Writing log failed with exception %s"(typeid(e));
                    debug writefln!"Trace: %s"(e.toString);
                }
            }
            catch (Exception e)
            {
            }
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
