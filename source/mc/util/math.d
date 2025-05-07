module mc.util.math;

import std.meta : AliasSeq, allSatisfy;
import std.traits : isIntegral;

@safe:

int sign(T)(const T value)
if (isIntegral!T)
    => value >= 0 ? 1 : -1;

auto ceilDiv(T1, T2)(T1 lhs, T2 rhs)
if (allSatisfy!(isIntegral, AliasSeq!(T1, T2)))
{
    const q = lhs / rhs;
    const r = lhs % rhs;
    if (r && lhs.sign == rhs.sign)
        return q + 1;
    return q;
}

@("ceilDiv")
unittest
{
    assert(ceilDiv(4, 2) == 2);
    assert(ceilDiv(3, 2) == 2);
    assert(ceilDiv(2, 2) == 1);
    assert(ceilDiv(1, 2) == 1);
    assert(ceilDiv(0, 2) == 0);
    assert(ceilDiv(-1, 2) == 0);
    assert(ceilDiv(-2, 2) == -1);
    assert(ceilDiv(-3, 2) == -1);
    assert(ceilDiv(-4, 2) == -2);
}
