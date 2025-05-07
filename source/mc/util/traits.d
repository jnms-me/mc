module mc.util.traits;

import std.checkedint : checked;

@safe:

enum size_t bitSize(T) = checked(T.sizeof * 8).get;

@("bitSize")
unittest
{
    static assert(bitSize!ubyte == 8);
    static assert(bitSize!ulong == 64);
    static assert(bitSize!(ulong[1024]) == 64 * 1024);
}