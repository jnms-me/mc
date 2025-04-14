module mc.util.meta;

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
