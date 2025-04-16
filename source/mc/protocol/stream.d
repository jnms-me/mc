module mc.protocol.stream;

import std.bitmanip : bigEndianToNative, nativeToBigEndian;
import std.conv : to;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import std.meta : AliasSeq;
import std.traits : isIntegral, Unqual;

import mc.protocol.nbt : Nbt;
import mc.util.meta : staticAmong;

@safe:

struct InputStream
{
    private immutable(ubyte)[] m_slice;

    this(immutable(ubyte)[] slice)
    {
        m_slice = slice;
    }

    immutable(ubyte)[] data() const
        => m_slice;

    bool empty() const
        => m_slice.length > 0;

    size_t bytesLength() const
        => m_slice.length;

    immutable(ubyte)[] readBytes(size_t count)
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
    private immutable(ubyte)[] m_arr;

    immutable(ubyte)[] data() const
        => m_arr;

    bool empty() const
        => m_arr.length > 0;

    size_t bytesLength() const
        => m_arr.length;

    void write(T)(const T value)
    if (staticAmong!(T, AliasSeq!(ubyte, byte, ushort, short, uint, int, ulong, long, float, double, char, bool)))
    {
        m_arr ~= nativeToBigEndian(value);
    }

    void write(T : E[n], E, size_t n)(const T value)
    if (__traits(compiles, write!E))
    {
        foreach (el; value)
            write!E(el);
    }

    void writeBytes(const immutable(ubyte)[] arr)
    {
        m_arr ~= arr;
    }

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

    void writePrefixedString(const immutable(char)[] s)
    {
        writeVar!int(s.length.to!int);
        m_arr ~= cast(const immutable(ubyte)[]) s;
    }

    void writeNbt(ref const Nbt nbt)
    {
        nbt.serialize(this);
    }
}

class EOFException : Exception
{
    mixin basicExceptionCtors;
}
