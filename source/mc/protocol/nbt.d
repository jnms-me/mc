module mc.protocol.nbt;

import std.algorithm : all, each, map;
import std.conv : to;
import std.exception : enforce;
import std.format : f = format;
import std.meta : AliasSeq;
import std.traits : isArray, isAssociativeArray, isSomeString, KeyType, Unqual, ValueType;

import mc.protocol.stream : OutputStream;
import mc.util.meta : staticAmong;

@safe:

struct Nbt
{
    enum TagType : ubyte
    {
        invalid   = 0xFF,

        byte_     = 0x01,
        short_    = 0x02,
        int_      = 0x03,
        long_     = 0x04,
        float_    = 0x05,
        double_   = 0x06,

        byteArray = 0x07,
        intArray  = 0x0B,
        longArray = 0x0C,
        string_   = 0x08,

        list      = 0x09,
        compound  = 0x0A,
        end       = 0x00,
    }

    private
    union Contents
    {
        byte byte_;
        short short_;
        int int_;
        long long_;
        float float_;
        double double_;

        const(byte)[] byteArray;
        const(int)[] intArray;
        const(long)[] longArray;
        const(char)[] string_;

        const(Nbt)[] list;
        const(Nbt)[string] compound;
    }

    private TagType m_tagType;
    private Contents m_contents;

scope:

    @disable this();
    @disable this(this);

    this(T)(T value)
    {
        enum string ct_typeName = {
            static if (staticAmong!(T, AliasSeq!(byte, short, int, long, float, double)))
                return T.stringof ~ "_";
            else static if (isArray!T)
            {
                alias UE = Unqual!(typeof(T.init[0]));
                static if (is(UE == byte))
                    return "byteArray";
                else static if (is(UE == int))
                    return "intArray";
                else static if (is(UE == long))
                    return "longArray";
                else static if (isSomeString!T)
                    return "string_";
                else static if (is(UE == Nbt))
                    return "list";
            }
            else static if (isAssociativeArray!T)
            {
                alias K = KeyType!T;
                alias V = ValueType!T;
                static if (is(K == string) && is(V : const(Nbt)))
                    return "compound";
            }
            assert(false, f!"Invalid type for Nbt ctor: %s"(T.stringof));
        }();

        m_tagType = mixin("TagType." ~ ct_typeName);
        mixin("m_contents." ~ ct_typeName) = value;
    }

    static pure nothrow @nogc
    typeof(this) emptyList()
        => typeof(this)(typeof(m_contents.list).init);

    static pure nothrow @nogc
    typeof(this) emptyCompound()
        => typeof(this)(typeof(m_contents.compound).init);
    
    TagType tagType() const
        => m_tagType;
    
    private @trusted pragma(inline, true)
    ref auto get(string ct_typeName)() inout return
    {
        enforce(m_tagType == mixin("TagType." ~ ct_typeName));
        return mixin("m_contents." ~ ct_typeName);
    }

    alias getByte      = get!"byte_";
    alias getShort     = get!"short_";
    alias getInt       = get!"int_";
    alias getLong      = get!"long_";
    alias getFloat     = get!"float_";
    alias getDouble    = get!"double_";
    alias getByteArray = get!"byteArray";
    alias getIntArray  = get!"intArray";
    alias getLongArray = get!"longArray";
    alias getString    = get!"string_";
    alias getList      = get!"list";
    alias getCompound  = get!"compound";

    private
    void serializeInternal(ref OutputStream output) const
    {
        switch (m_tagType)
        {
        case TagType.byte_:
            output.write!byte(getByte);
            break;
        case TagType.short_:
            output.write!short(getShort);
            break;
        case TagType.int_:
            output.write!int(getInt);
            break;
        case TagType.long_:
            output.write!long(getLong);
            break;
        case TagType.float_:
            output.write!float(getFloat);
            break;
        case TagType.double_:
            output.write!double(getDouble);
            break;

        case TagType.byteArray:
            output.write!int(getByteArray.length.to!int);
            getByteArray.each!((byte el) => output.write!byte(el));
            break;
        case TagType.intArray:
            output.write!int(getIntArray.length.to!int);
            getIntArray.each!((int el) => output.write!int(el));
            break;
        case TagType.longArray:
            output.write!int(getLongArray.length.to!int);
            getLongArray.each!((long el) => output.write!long(el));
            break;
        case TagType.string_:
            output.write!ushort(getString.length.to!ushort); // Strings have a 2-byte length instead
            getString.each!((char el) => output.write!char(el)); // Write utf-8 codepoints as is
            break;

        case TagType.list:
            {
                TagType listTagType = TagType.end;
                if (getList.length)
                {
                    listTagType = getList[0].tagType;
                    enforce(
                        getList[1 .. $]
                            .map!((ref el) => el.tagType)
                            .all!(el => el == listTagType), // true for []
                        "All list elements must be of the same type",
                    );
                }
                output.write!ubyte(listTagType);
                output.write!int(getList.length.to!int);
                getList.each!((ref el) => el.serializeInternal(output));
            }
            break;

        case TagType.compound:
            {
                foreach (const immutable(char)[] key, ref const Nbt value; getCompound)
                {
                    output.write!ubyte(value.tagType);
                    output.write!ushort(key.length.to!ushort);
                    output.writeBytes(cast(const immutable(ubyte)[]) key);
                    value.serializeInternal(output);
                }
                output.write!ubyte(TagType.end);
            }
            break;

        default: 
            assert(false, "Invalid Nbt tagType, did you initialize it?");
        }
    }

    void serialize(ref OutputStream output) const
    {
        enforce(tagType == TagType.compound, "Can only serialize compound tags");
        output.write!ubyte(TagType.compound); // Root compound tag has no name
        serializeInternal(output);
    }
}

@("Nbt ctor")
unittest
{
    foreach (T; AliasSeq!(byte, short, int, long, float, double))
        Nbt(T.init);
    foreach (T; AliasSeq!(ubyte, ushort, uint, ulong, real, char, wchar, dchar))
        static assert(!is(typeof(Nbt(T.init))));
    foreach (T; AliasSeq!(byte[], int[], long[], char[]))
        Nbt(T.init);
    foreach (T; AliasSeq!(ubyte[], uint[], ulong[], float[], dchar[]))
        static assert(!is(typeof(Nbt(T.init))));
}

@("Nbt getters")
unittest
{
    assert(Nbt(byte.init).getByte == byte.init);
}
