module mc.protocol.stream;

import std.array : Appender;
import std.bitmanip : bigEndianToNative, nativeToBigEndian;
import std.conv : to;
import std.exception : assumeWontThrow, basicExceptionCtors, enforce;
import std.format : f = format;
import std.meta : AliasSeq;
import std.traits : isIntegral, Unshared;

import mc.util.meta : staticAmong;

@safe:

struct InputStream
{
    private
    {
        immutable(ubyte)[] m_slice;
    }

scope:
pure:
    this(immutable(ubyte)[] slice)
    {
        m_slice = slice;
    }

    nothrow @nogc
    immutable(ubyte)[] data() const
        => m_slice;

    nothrow @nogc
    bool empty() const
        => m_slice.length > 0;

    nothrow @nogc
    size_t bytesLength() const
        => m_slice.length;

    immutable(ubyte)[] readBytes(in size_t count)
    {
        enforce!EOFException(m_slice.length >= count);
        scope (exit) m_slice = m_slice[count .. $];
        return m_slice[0 .. count];
    }

    T read(T)()
    if (staticAmong!(T, AliasSeq!(ubyte, byte, ushort, short, uint, int, ulong, long, float, double, char, bool)))
    {
        const ubyte[T.sizeof] bytes = readBytes(T.sizeof);
        return bigEndianToNative!T(bytes);
    }

    E[n] read(T : E[n], E, size_t n)()
    if (__traits(compiles, read!E))
    {
        E[n] value;
        foreach (ref el; value)
            el = read!E;
        return value;
    }

    int readVar(T)()
    if (isIntegral!T && T.sizeof > 1)
    {
        enum size_t maxLength = T.sizeof * 8 / 7;

        int result;
        for (size_t i;; i++)
        {
            enforce(i < maxLength, f!"Found too many bytes reading variable %s integral"(T.stringof));
            ubyte b = read!ubyte;
            result |= (b & 0b0111_1111) << (i * 7);
            if ((b & 0b1000_0000) == 0)
                break;
        }
        return result;
    }

    string readPrefixedString()
    {
        const size_t length = readVar!int;
        return cast(immutable(char)[]) readBytes(length);
    }
}

struct OutputStream
{
    private
    {
        Appender!(immutable(ubyte)[]) m_appender;
    }

scope:
pure:
    private this(bool disableFieldCtor) {assert(false);}

    nothrow @nogc
    immutable(ubyte)[] data() const
        => m_appender[];

    nothrow @nogc
    bool empty() const
        => m_appender[].length > 0;

    nothrow @nogc
    size_t bytesLength() const
        => m_appender[].length;

    nothrow
    void write(T)(in T value)
    if (staticAmong!(T, AliasSeq!(ubyte, byte, ushort, short, uint, int, ulong, long, float, double, char, bool)))
    {
        m_appender ~= nativeToBigEndian(value)[];
    }

    nothrow
    void write(T : E[n], E, size_t n)(in T value)
    if (__traits(compiles, write!E))
    {
        foreach (el; value)
            write!E(el);
    }

    nothrow
    void writeBytes(in immutable(ubyte)[] arr)
    {
        m_appender ~= arr;
    }

    nothrow
    void writeVar(T)(T value)
    if (staticAmong!(T, AliasSeq!(uint, int, ulong, long)))
    {
        do
        {
            ubyte b;
            b |= (value & 0b0111_1111);
            value >>= 7;
            b |= (value != 0) << 7;
            write!ubyte(b);
        }
        while (value);
    }

    nothrow
    void writeArray(T : E[], E)(in T arr)
    {
        foreach (el; arr)
        {
            Unshared!E cpy = el;
            write(cpy);
        }
    }

    nothrow
    void writePrefixedArray(T : E[], E)(in T arr)
    {
        writeVar!int(arr.length.to!int.assumeWontThrow);
        writeArray(arr);
    }

    alias writePrefixedString = writePrefixedArray;
}

class EOFException : Exception
{
    mixin basicExceptionCtors;
}
