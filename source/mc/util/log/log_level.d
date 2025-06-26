module mc.util.log.log_level;

import std.array : Appender;
import std.ascii : newline;

import mc.util.log.ansi_color : AnsiColor;

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
            Appender!string appender;
            foreach (part; fmtParts)
                appender ~= part;
            appender ~= AnsiColor.reset.toString;
            appender ~= newline;
            return appender[];
        }();
    }

    package(mc.util.log) nothrow @nogc
    string getFmt() const
        => m_fmt;

    nothrow @nogc
    int opCmp(in LogLevel rhs) const
        => int(m_level - rhs.m_level);
}
