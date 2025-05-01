module mc.log;

import std.algorithm : map;
import std.stdio : writef, writefln;
import std.format : f = format;
import mc.config;
import mc.ansi_color : AnsiColor;

@safe nothrow:

struct LogLevel
{
    enum trace      = typeof(this)(0, AnsiColor.reset.fg.light.italic ~ "[TRACE] %s");
    enum debug_     = typeof(this)(1, AnsiColor.reset.fg.light ~ "[DEBUG] %s");
    enum diagnostic = typeof(this)(2, "[DIAG] %s");
    enum info       = typeof(this)(3, AnsiColor.reset.fg.green ~ "[INFO] %s");
    enum warning    = typeof(this)(4, AnsiColor.reset.fg.yellow ~ "[WARN] %s");
    enum error      = typeof(this)(5, AnsiColor.reset.fg.red.bold ~ "[ERROR] %s");
    enum critical   = typeof(this)(6, AnsiColor.reset.bg.red.bold ~ "[CRIT] %s");
    enum fatal      = typeof(this)(7, AnsiColor.reset.bg.red.light.bold ~ "[FATAL] %s");

    uint level;
    string fmt;

    private
    this(uint level, string fmt)
    {
        this.level = level;
        this.fmt = fmt ~ AnsiColor.reset.toString;
    }
}

struct Logger
{
    private string m_id = "Unspecified";

    this(string id)
    in (id.length)
    {
        m_id = id;
    }

    static
    typeof(this) moduleLogger(string mod = __MODULE__)
        => typeof(this)(mod);

const:
    typeof(this) derive(string id)
        => typeof(this)(m_id ~ ": " ~ id);

    void log(LogLevel level, string fmt, Args...)(lazy Args args)
    {
        static if (level.level >= Config.ct_logLevel.level)
        {
            try
            {
                // TODO: split writing and formatting to differentiate lazy args eval exceptions from log exceptions
                try
                    writefln!(level.fmt)(f!"%s: %s"(m_id, f!fmt(args)));
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

    void trace   (string fmt, Args...)(lazy Args args) => log!(LogLevel.trace,      fmt, Args)(args);
    void dbg     (string fmt, Args...)(lazy Args args) => log!(LogLevel.debug_,     fmt, Args)(args);
    void diag    (string fmt, Args...)(lazy Args args) => log!(LogLevel.diagnostic, fmt, Args)(args);
    void info    (string fmt, Args...)(lazy Args args) => log!(LogLevel.info,       fmt, Args)(args);
    void warn    (string fmt, Args...)(lazy Args args) => log!(LogLevel.warning,    fmt, Args)(args);
    void error   (string fmt, Args...)(lazy Args args) => log!(LogLevel.error,      fmt, Args)(args);
    void critical(string fmt, Args...)(lazy Args args) => log!(LogLevel.critical,   fmt, Args)(args);
    void fatal   (string fmt, Args...)(lazy Args args) => log!(LogLevel.fatal,      fmt, Args)(args);
}
