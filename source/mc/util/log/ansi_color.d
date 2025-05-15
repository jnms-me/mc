module mc.util.log.ansi_color;

import std.exception : assumeWontThrow;
import std.format : f = format;

@safe:

private
enum string ansiColor(string modifier, string m_color)
    = f!"\x1b[%s;%sm"(modifier, m_color);

struct AnsiColor
{
    enum AnsiColor reset = AnsiColor.init;

    private
    {
        const(uint)[] m_prefix;
        uint m_color;
    }

scope:
pure nothrow:
    private @nogc
    this(in uint[] prefix, in uint color)
    {
        m_prefix = prefix;
        m_color = color;
    }

const:
    AnsiColor fg() => AnsiColor(m_prefix, m_color + 30);
    AnsiColor bg() => AnsiColor(m_prefix, m_color + 40);
    
    AnsiColor bold()          => AnsiColor(m_prefix ~ 1, m_color);
    AnsiColor italic()        => AnsiColor(m_prefix ~ 3, m_color);
    AnsiColor underline()     => AnsiColor(m_prefix ~ 3, m_color);
    AnsiColor strikethrough() => AnsiColor(m_prefix ~ 9, m_color);
    
    AnsiColor black()  => AnsiColor(m_prefix, m_color);
    AnsiColor red()    => AnsiColor(m_prefix, m_color + 1);
    AnsiColor green()  => AnsiColor(m_prefix, m_color + 2);
    AnsiColor yellow() => AnsiColor(m_prefix, m_color + 3);

    AnsiColor light() => AnsiColor(m_prefix, m_color + 60);

    string toString() const
    {
        const numbers = m_prefix ~ [m_color];
        return f!"\033[%(%u;%)m"(numbers).assumeWontThrow;
    }
    
    alias toString this;
}
