module mc.world.position;

import std.algorithm : all, map, sum;
import std.conv : roundTo, to;
import std.exception : assumeWontThrow;
import std.math : isFinite, sqrt;
import std.traits : isFloatingPoint, isIntegral, isNumeric, Unqual;

import mc.util.meta : staticAmong;
import mc.world.chunk.chunk : ct_chunkBlockLength;

@safe:

struct Vec3(T)
if (isNumeric!T)
{
    static if (isIntegral!T)
        private alias F = double; // Floating point type used for some calculations

    enum typeof(this) origin = typeof(this).init;

    private
    {
        T[3] m_arr = T(0);
    }

pure:
    scope
    invariant
    {
        static if (isFloatingPoint!T)
            assert(m_arr[].all!isFinite);
    }

    nothrow @nogc
    this(in T[3] arr) scope
    {
        m_arr = arr;
    }

    nothrow @nogc
    this(in T x, in T y, in T z) scope
    {
        m_arr = [x, y, z];
    }

    nothrow @nogc
    {
        ref inout(T[3]) array() inout => m_arr;

        ref inout(T) x() inout => m_arr[0];
        ref inout(T) y() inout => m_arr[1];
        ref inout(T) z() inout => m_arr[2];
    }

    nothrow
    T length() scope const
    {
        T sum = m_arr[].map!"a^^2".sum;
        static if (isFloatingPoint!T)
            return sum.sqrt;
        else
            return sum.to!F.sqrt.roundTo!T.assumeWontThrow;
    }

    nothrow @nogc
    auto opUnary(string op)() scope const
    {
        Unqual!(typeof(this)) ret;
        ret.m_arr = mixin(op ~ "m_arr[]");
        return ret;
    }

    nothrow @nogc
    auto opBinary(string op)(in T rhs) scope const
    {
        Vec3!T ret;
        ret.m_arr = mixin("m_arr[]" ~ op ~ "rhs");
        return ret;
    }

    nothrow @nogc
    auto opBinary(string op)(in Vec3!T rhs) scope const
    {
        Vec3!T ret;
        ret.m_arr = mixin("m_arr[]" ~ op ~ "rhs.m_arr[]");
        return ret;
    }

    alias array this;
}

struct ChunkPos
{
    private
    {
        Vec3!int m_vector;
    }

pure:
    nothrow @nogc
    this(Vec3!int vector) scope
    {
        m_vector = vector;
    }

    nothrow @nogc
    this(int x, int y, int z) scope
    {
        m_vector = Vec3!int(x, y, z);
    }

    nothrow @nogc
    ref vector() inout => m_vector;

    alias vector this;
}

struct BlockPos
{
    private
    {
        Vec3!int m_vector;
    }

pure:
    nothrow @nogc
    this(Vec3!int vector)
    {
        m_vector = vector;
    }

    nothrow @nogc
    this(int x, int y, int z)
    {
        m_vector = Vec3!int(x, y, z);
    }

    nothrow @nogc
    ref vector() inout => m_vector;

    nothrow @nogc
    ChunkPos toChunkPos() scope const
    {
        auto toChunkPos = ChunkPos(m_vector);
        foreach (ref int el; toChunkPos.vector)
        {
            if (el >= 0)
                el = el / 16;
            else
                el = el / 16 - 1;
        }
        return toChunkPos;
    }

    nothrow @nogc
    ChunkRelativeBlockPos toChunkRelativePos() scope const
    {
        auto toChunkRelativePos = ChunkRelativeBlockPos(m_vector);
        foreach (ref int el; toChunkRelativePos.vector)
        {
            el %= 16;
            if (el < 0)
                el += 16;
        }
        return toChunkRelativePos;
    }

    alias vector this;
}

struct ChunkRelativeBlockPos
{
    private
    {
        Vec3!int m_vector;
    }

    scope
    invariant
    {
        assert(m_vector[].all!(el => el >= 0));
        assert(m_vector[].all!(el => el < 16));
    }

pure:
    nothrow @nogc
    this(in Vec3!int vector) scope
    {
        m_vector = vector;
        wrapAround;
    }

    nothrow @nogc
    this(in int x, in int y, in int z) scope
    {
        m_vector = Vec3!int(x, y, z);
        wrapAround;
    }

    private nothrow @nogc
    void wrapAround() scope
    {
        m_vector[] %= 16;
        foreach (ref int el; m_vector)
            if (el < 0)
                el += 16;
    }

    nothrow @nogc
    ref vector() inout => m_vector;

    nothrow @nogc
    size_t toIndex() scope const
        => x + (z * ct_chunkBlockLength) + (y * ct_chunkBlockLength ^^ 2);
    
    alias vector this;
}

struct ContinuousPos
{
    private
    {
        Vec3!double m_vector;
    }

pure:
    nothrow @nogc
    this(Vec3!double vector) scope
    {
        m_vector = vector;
    }

    nothrow @nogc
    this(double x, double y, double z) scope
    {
        m_vector = Vec3!double(x, y, z);
    }

    nothrow @nogc
    ref vector() inout => m_vector;

    nothrow
    BlockPos toBlockPos() scope const
        => BlockPos(
            x.roundTo!int.assumeWontThrow,
            y.roundTo!int.assumeWontThrow,
            z.roundTo!int.assumeWontThrow,
        );

    alias vector this;
}