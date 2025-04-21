module mc.util.meta;

import std.meta : AliasSeq, Stride;

@safe:

enum size_t staticAmong(needle, haystack...) = {
    foreach (i, el; haystack)
        if (is(needle == el))
            return i + 1;
    return 0;
}();

@("staticAmong")
unittest
{
    static assert(staticAmong!(int, ushort, int, string));
    static assert(!staticAmong!(int, ushort, uint, string));
}

alias getMember(alias T, string member) = __traits(getMember, T, member);

template members(alias T)
{
    alias members = AliasSeq!();
    static foreach (string member; __traits(allMembers, T))
        members = AliasSeq!(members, __traits(getMember, T, member));
}

enum string stringof(alias arg) = arg.stringof;