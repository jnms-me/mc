module mc.log;

import std.stdio : writefln;
import std.format : format;

@safe:

immutable LogLevel g_logLevel;

shared static this()
{
    debug g_logLevel = LogLevel.debug_;
    else g_logLevel = LogLevel.info;
}

enum LogLevel
{
    debug_,
    diagnostic,
    info,
    warn,
    error,
    critical,
    fatal,
}

private nothrow
void log(LogLevel level, string fmt, Args...)(lazy Args args)
{
    if (level >= g_logLevel)
    {
        try
        {
            try
                writefln!fmt(args);
            catch (Exception e)
                writefln!"Writing log failed with exception %s"(typeid(e));
        }
        catch (Exception e)
        {
        }
    }
}

void logDebug   (string fmt, Args...)(lazy Args args) => log!(LogLevel.debug_,     fmt, Args)(args);
void logInfo    (string fmt, Args...)(lazy Args args) => log!(LogLevel.diagnostic, fmt, Args)(args);
void logWarn    (string fmt, Args...)(lazy Args args) => log!(LogLevel.warn,       fmt, Args)(args);
void logError   (string fmt, Args...)(lazy Args args) => log!(LogLevel.error,      fmt, Args)(args);
void logCritical(string fmt, Args...)(lazy Args args) => log!(LogLevel.critical,   fmt, Args)(args);
void logFatal   (string fmt, Args...)(lazy Args args) => log!(LogLevel.fatal,      fmt, Args)(args);
