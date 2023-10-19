apis = [
    @signature JLFreeFromMe(ref::JV)::Cvoid
    @signature JLEval(out::Out{JV}, var"module"::JV, code::TyList{NativeChar})::ErrorCode
    @signature FetchJLErrorSize(size::Out{Int64})::ErrorCode
    @signature FetchJLError(out::Out{JSym}, msgBuffer::TyList{NativeChar})::ErrorCode
    @signature JSymToJV(sym::JSym)::JV
    @signature JLTypeOf(value::JV)::JV
    @signature JLTypeOfAsTypeSlot(value::JV)::Int64
    @signature JLIsInstanceWithTypeSlot(value::JV, slot::Int64)::Bool
    @signature JLCall(out::Out{JV}, func::JV, args::TyList{JV}, kwargs::TyList{TyTuple{JSym,JV}})::ErrorCode
    @signature JLDotCall(out::Out{JV}, func::JV, args::TyList{JV}, kwargs::TyList{TyTuple{JSym,JV}})::ErrorCode
    @signature JLCompare(out::Out{Bool}, cmp::Compare, a::JV, b::JV)::ErrorCode
    @signature JLGetProperty(out::Out{JV}, self::JV, property::JSym)::ErrorCode
    @signature JLSetProperty(self::JV, property::JSym, value::JV)::ErrorCode
    @signature JLHasProperty(out::Out{Bool}, self::JV, property::JSym)::ErrorCode
    @signature JLGetIndex(out::Out{JV}, self::JV, index::TyList{JV})::ErrorCode
    @signature JLGetIndexI(out::Out{JV}, self::JV, index::Int64)::ErrorCode
    @signature JLSetIndex(self::JV, index::TyList{JV}, value::JV)::ErrorCode
    @signature JLSetIndexI(self::JV, index::Int64, value::JV)::ErrorCode
    @signature JLGetSymbol(out::Out{JSym}, value::JV, doCast::Bool)::ErrorCode
    @signature JLGetBool(out::Out{Bool}, value::JV, doCast::Bool)::ErrorCode
    @signature JLGetUInt8(out::Out{UInt8}, value::JV, doCast::Bool)::ErrorCode
    @signature JLGetUInt32(out::Out{UInt32}, value::JV, doCast::Bool)::ErrorCode
    @signature JLGetUInt64(out::Out{UInt64}, value::JV, doCast::Bool)::ErrorCode
    @signature JLGetInt32(out::Out{Int32}, value::JV, doCast::Bool)::ErrorCode
    @signature JLGetInt64(out::Out{Int64}, value::JV, doCast::Bool)::ErrorCode
    @signature JLGetSingle(out::Out{Float32}, value::JV, doCast::Bool)::ErrorCode
    @signature JLGetDouble(out::Out{Float64}, value::JV, doCast::Bool)::ErrorCode
    @signature JLGetComplexF64(out::Out{ComplexF64}, value::JV, doCast::Bool)::ErrorCode
    @signature JLGetUTF8String(out::TyList{NativeChar}, value::JV)::ErrorCode
    @signature JLGetArrayPointer(out::Out{Ptr{UInt8}}, len::Out{Int64}, value::JV)::ErrorCode
    @signature JSymFromString(out::Out{JSym}, value::TyList{NativeChar})::ErrorCode
    @signature ToJLInt64(out::Out{JV}, value::Int64)::ErrorCode
    @signature ToJLUInt64(out::Out{JV}, value::UInt64)::ErrorCode
    @signature ToJLUInt32(out::Out{JV}, value::UInt32)::ErrorCode
    @signature ToJLUInt8(out::Out{JV}, value::UInt8)::ErrorCode
    @signature ToJLString(out::Out{JV}, value::TyList{NativeChar})::ErrorCode
    @signature ToJLBool(out::Out{JV}, value::Bool)::ErrorCode
    @signature ToJLFloat64(out::Out{JV}, value::Float64)::ErrorCode
    @signature ToJLComplexF64(out::Out{JV}, value::ComplexF64)::ErrorCode

    @signature JLStrVecWriteEltWithUTF8(self::JV, i::Int64, value::TyList{NativeChar})::ErrorCode
    @signature JLStrVecGetEltNBytes(out::Out{Int64}, self::JV, i::Int64)::ErrorCode
    @signature JLStrVecReadEltWithUTF8(self::JV, i::Int64, value::TyList{NativeChar})::ErrorCode

    @signature JLTypeToIdent(out::Out{Int64}, jv::JV)::ErrorCode
    @signature JLTypeFromIdent(out::Out{JV}, slot::Int64)::ErrorCode

    @signature JLNew_F64Array(out::Out{JV}, dims::TyList{Int64})::ErrorCode
    @signature JLNew_U64Array(out::Out{JV}, dims::TyList{Int64})::ErrorCode
    @signature JLNew_U32Array(out::Out{JV}, dims::TyList{Int64})::ErrorCode
    @signature JLNew_U8Array(out::Out{JV}, dims::TyList{Int64})::ErrorCode
    @signature JLNew_I64Array(out::Out{JV}, dims::TyList{Int64})::ErrorCode
    @signature JLNew_BoolArray(out::Out{JV}, dims::TyList{Int64})::ErrorCode
    @signature JLNew_ComplexF64Array(out::Out{JV}, dims::TyList{Int64})::ErrorCode
    @signature JLNew_StringVector(out::Out{JV}, length::Int64)::ErrorCode

    @signature JLArray_Size(out::Out{Int64}, self::JV, i::Int64)::ErrorCode
    @signature JLArray_Rank(out::Out{Int64}, self::JV)::ErrorCode

    @signature JLError_EnableBackTraceMsg(status::Bool)::Cvoid
    @signature JLError_HasBackTraceMsg()::UInt8

    @signature JLError_FetchMsgSize(size::Out{Int64})::ErrorCode
    @signature JLError_FetchMsgStr(out::Out{JSym}, msgBuffer::TyList{NativeChar})::ErrorCode

    @signature JLCommonTag(value::JV)::UInt8
]
