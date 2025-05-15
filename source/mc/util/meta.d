module mc.util.meta;

import std.meta : AliasSeq;

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

template members(alias T)
{
    alias members = AliasSeq!();
    static foreach (string member; __traits(allMembers, T))
        members = AliasSeq!(members, __traits(getMember, T, member));
}

enum string stringof(alias arg) = arg.stringof;

mixin template enumSwitch(alias value, alias handler, args...)
if (is(typeof(value) == enum))
{
    auto sw()
    {
        import std.traits : EnumMembers;

        alias Enum = typeof(value);

        final switch (value)
        {
            static foreach (i, alias enumMember; EnumMembers!Enum)
            {
            case enumMember:
                return handler!enumMember(args);
            }
        }
    }
}
