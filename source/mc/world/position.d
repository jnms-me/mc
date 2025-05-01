module mc.world.position;

import std.algorithm : all, map, sum;
import std.conv : to;
import std.math : round, sqrt;
import std.traits : isFloatingPoint, isIntegral, isNumeric, Unqual;

import mc.util.meta : staticAmong;

struct Vec3(T)
if (isNumeric!T)
{
    private
    {
        static if (isIntegral!T)
            alias F = double; // Floating point type used for some calculations

        T[3] m_arr = T(0);
    }

    enum typeof(this) origin = typeof(this).init;

    this(T[3] arr)
    {
        m_arr = arr;
    }

    this(T x, T y, T z)
    {
        m_arr = [x, y, z];
    }

    ref inout(T[3]) array() inout => m_arr;
    alias array this;

    ref inout(T) x() inout => m_arr[0];
    ref inout(T) z() inout => m_arr[1];
    ref inout(T) y() inout => m_arr[2];

    T length() const
    {
        T sum = m_arr[].map!"a^^2".sum;
        static if (isFloatingPoint!T)
            return sum.sqrt;
        else
            return sum.to!F.sqrt.round.to!T;
    }

    auto opUnary(string op)() const
    {
        Unqual!(typeof(this)) ret;
        ret.m_arr = mixin(op ~ "m_arr[]");
        return ret;
    }

    auto opBinary(string op)(const T rhs) const
    {
        Unqual!(typeof(this)) ret;
        ret.m_arr = mixin("m_arr[]" ~ op ~ "rhs");
        return ret;
    }

    auto opBinary(string op)(const typeof(this) rhs) const
    {
        Unqual!(typeof(this)) ret;
        ret.m_arr = mixin("m_arr[]" ~ op ~ "rhs.m_arr[]");
        return ret;
    }
}

struct ChunkPos
{
    private
    {
        Vec3!int m_vector;
    }

    this(Vec3!int vector)
    {
        m_vector = vector;
    }

    ref vector() inout
        => m_vector;
}

struct BlockPos
{
    private
    {
        Vec3!int m_vector;
    }

    this(Vec3!int vector)
    {
        m_vector = vector;
    }

    this(int x, int y, int z)
    {
        m_vector = Vec3!int(x, y, z);
    }

    ref vector() inout
        => m_vector;

    ChunkPos chunkPos() scope const
    {
        auto chunkPos = ChunkPos(m_vector);
        foreach (ref int el; chunkPos.vector)
        {
            if (el >= 0)
                el = el / 16;
            else
                el = el / 16 - 1;
        }
        return chunkPos;
    }

    ChunkRelativeBlockPos chunkRelativePos() scope const
    {
        auto chunkRelativePos = ChunkRelativeBlockPos(m_vector);
        foreach (ref int el; chunkRelativePos.vector)
        {
            el %= 16;
            if (el < 0)
                el += 16;
        }
        return chunkRelativePos;
    }
}

struct ChunkRelativeBlockPos
{
    private
    {
        Vec3!int m_vector;
    }

    invariant
    {
        assert(m_vector[].all!(el => el >= 0));
        assert(m_vector[].all!(el => el < 16));
    }

    this(Vec3!int vector)
    {
        m_vector = vector;
        wrapAround;
    }

    this(int x, int y, int z)
    {
        m_vector = Vec3!int(x, y, z);
        wrapAround;
    }

    ref vector() inout
        => m_vector;

    private
    void wrapAround()
    {
        m_vector[] %= 16;
        foreach (ref int el; m_vector)
            if (el < 0)
                el += 16;
    }
}
