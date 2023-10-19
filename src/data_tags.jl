# used for deno bindings for auto conversion
const Tag_I32 = UInt8(1)
const Tag_I64 = UInt8(2)
const Tag_U32 = UInt8(3)
const Tag_U64 = UInt8(4)
const Tag_F32 = UInt8(5)
const Tag_F64 = UInt8(6)
const Tag_B8 = UInt8(7)
const Tag_String = UInt8(8)
const Tag_Vector = UInt8(9)
const Tag_SimpleVector = UInt8(10)
const Tag_Symbol = UInt8(11)
const Tag_Unknown = UInt8(100)

function JLCommonTag(self::JV)::UInt8
    a = JV_LOAD(self)
    if a isa Int32
        return Tag_I32
    elseif a isa Int64
        return Tag_I64
    elseif a isa UInt32
        return Tag_U32
    elseif a isa UInt64
        return Tag_U64
    elseif a isa Float32
        return Tag_F32
    elseif a isa Float64
        return Tag_F64
    elseif a isa Bool
        return Tag_B8
    elseif a isa String
        return Tag_String
    elseif a isa Symbol
        return Tag_Symbol
    elseif a isa Core.SimpleVector
        return Tag_SimpleVector
    elseif a isa Vector
        return Tag_Vector
    else
        return Tag_Unknown
    end
end