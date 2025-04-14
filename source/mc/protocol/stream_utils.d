module mc.protocol.stream_utils;

import std.bitmanip : bigEndianToNative, nativeToBigEndian;
import std.exception : basicExceptionCtors, enforce;
import std.meta : AliasSeq;
import std.traits : isIntegral, Unqual;

import mc.protocol.nbt : Nbt;
import mc.util.meta : staticAmong;

@safe:

//
// Input
//

Unqual!T read(T)(ref const(ubyte)[] input)
if (isIntegral!T || staticAmong!(Unqual!T, AliasSeq!(bool, char, float, double)))
{
    enf!EOF(input.length >= T.sizeof);
    Unqual!T value = bigEndianToNative!(Unqual!T)(input[0 .. T.sizeof]);
    input = input[T.sizeof .. $];
    return value;
}

Unqual!E[n] read(T : E[n], E, size_t n)(ref const(ubyte)[] input)
if (__traits(compiles, read!E))
{
    enf!EOF(input.length >= n);
    Unqual!E[n] value;
    foreach (ref el; value)
        el = input.read!E;
    return value;
}

ubyte[] readBytes(ref const(ubyte)[] input, size_t count)
{
    enf!EOF(input.length >= count);
    ubyte[] ret = input[0 .. count].dup;
    input = input[count .. $];
    return ret;
}

string readString(ref const(ubyte)[] input)
{
    size_t length = input.readVar!int;
    return (cast(char[]) input.readBytes(length)).idup;
}

int readVar(T)(ref const(ubyte)[] input)
if (isIntegral!T && T.sizeof > 1)
{
    enum size_t maxLength = T.sizeof * 8 / 7;

    int result;
    for (size_t i;; i++)
    {
        enf(i < maxLength, "Found too many bytes reading var " ~ T.sizeof);
        ubyte b = input.read!ubyte;
        result |= (b & 0b0111_1111) << (i * 7);
        if ((b & 0b1000_0000) == 0)
            break;
    }
    return result;
}

//
// Output
//

void write(T)(ref const(ubyte)[] output, const T value)
if (isIntegral!T || staticAmong!(Unqual!T, AliasSeq!(bool, char, float, double)))
{
    output ~= nativeToBigEndian(value);
}

void write(T : E[n], E, size_t n)(ref const(ubyte)[] output, const T value)
if (__traits(compiles, write!E))
{
    foreach (el; value)
        output.write!E(el);
}

void writeBytes(ref const(ubyte)[] output, const ubyte[] arr)
{
    output ~= arr;
}

void writeString(ref const(ubyte)[] output, const char[] s)
{
    output.writeVar!int(cast(int) s.length);
    output ~= cast(const ubyte[]) s;
}

void writeVar(T)(ref const(ubyte)[] output, const T value)
if (isIntegral!T && T.sizeof > 1)
{
    Unqual!T mutValue = value;
    do
    {
        ubyte b;
        b |= cast(ubyte)(mutValue & 0b0111_1111);
        mutValue >>= 7;
        b |= (mutValue != 0) << 7;
        output.write!ubyte(cast(const) b);
    }
    while (mutValue);
}

void writeNbt(ref const(ubyte)[] output, ref const Nbt nbt)
{
    nbt.serialize(output);
}

//
// Utils
//

private alias enf = enforce;
private alias EOF = EOFException;

class EOFException : Exception
{
    mixin basicExceptionCtors;
}
