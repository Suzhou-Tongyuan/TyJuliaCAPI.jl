# This file is generated. Do not modify it directly.
function get_capi(name::Cstring, fptr_ref::Ptr{Ptr{Cvoid}}, status_ref::Ptr{Bool})
    jname = unsafe_string(name)
    try
        if jname == "JLFreeFromMe"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLFreeFromMe, Nothing, (JV,)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLEval"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLEval, ErrorCode, (Ptr{JV}, JV, TyList{UInt8})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "FetchJLErrorSize"
            unsafe_store!(
                fptr_ref,
                @cfunction(FetchJLErrorSize, ErrorCode, (Ptr{Int64},)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "FetchJLError"
            unsafe_store!(
                fptr_ref,
                @cfunction(FetchJLError, ErrorCode, (Ptr{JSym}, TyList{UInt8})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JSymToJV"
            unsafe_store!(
                fptr_ref,
                @cfunction(JSymToJV, JV, (JSym,)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLTypeOf"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLTypeOf, JV, (JV,)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLTypeOfAsTypeSlot"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLTypeOfAsTypeSlot, Int64, (JV,)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLIsInstanceWithTypeSlot"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLIsInstanceWithTypeSlot, Bool, (JV, Int64)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLCall"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLCall, ErrorCode, (Ptr{JV}, JV, TyList{JV}, TyList{TyTuple{JSym, JV}})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLDotCall"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLDotCall, ErrorCode, (Ptr{JV}, JV, TyList{JV}, TyList{TyTuple{JSym, JV}})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLCompare"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLCompare, ErrorCode, (Ptr{Bool}, Compare, JV, JV)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetProperty"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetProperty, ErrorCode, (Ptr{JV}, JV, JSym)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLSetProperty"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLSetProperty, ErrorCode, (JV, JSym, JV)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLHasProperty"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLHasProperty, ErrorCode, (Ptr{Bool}, JV, JSym)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetIndex"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetIndex, ErrorCode, (Ptr{JV}, JV, TyList{JV})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetIndexI"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetIndexI, ErrorCode, (Ptr{JV}, JV, Int64)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLSetIndex"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLSetIndex, ErrorCode, (JV, TyList{JV}, JV)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLSetIndexI"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLSetIndexI, ErrorCode, (JV, Int64, JV)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetSymbol"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetSymbol, ErrorCode, (Ptr{JSym}, JV, Bool)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetBool"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetBool, ErrorCode, (Ptr{Bool}, JV, Bool)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetUInt8"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetUInt8, ErrorCode, (Ptr{UInt8}, JV, Bool)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetUInt32"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetUInt32, ErrorCode, (Ptr{UInt32}, JV, Bool)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetUInt64"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetUInt64, ErrorCode, (Ptr{UInt64}, JV, Bool)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetInt32"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetInt32, ErrorCode, (Ptr{Int32}, JV, Bool)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetInt64"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetInt64, ErrorCode, (Ptr{Int64}, JV, Bool)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetSingle"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetSingle, ErrorCode, (Ptr{Float32}, JV, Bool)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetDouble"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetDouble, ErrorCode, (Ptr{Float64}, JV, Bool)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetComplexF64"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetComplexF64, ErrorCode, (Ptr{ComplexF64}, JV, Bool)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetUTF8String"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetUTF8String, ErrorCode, (TyList{UInt8}, JV)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLGetArrayPointer"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLGetArrayPointer, ErrorCode, (Ptr{Ptr{UInt8}}, Ptr{Int64}, JV)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JSymFromString"
            unsafe_store!(
                fptr_ref,
                @cfunction(JSymFromString, ErrorCode, (Ptr{JSym}, TyList{UInt8})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "ToJLInt64"
            unsafe_store!(
                fptr_ref,
                @cfunction(ToJLInt64, ErrorCode, (Ptr{JV}, Int64)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "ToJLUInt64"
            unsafe_store!(
                fptr_ref,
                @cfunction(ToJLUInt64, ErrorCode, (Ptr{JV}, UInt64)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "ToJLUInt32"
            unsafe_store!(
                fptr_ref,
                @cfunction(ToJLUInt32, ErrorCode, (Ptr{JV}, UInt32)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "ToJLUInt8"
            unsafe_store!(
                fptr_ref,
                @cfunction(ToJLUInt8, ErrorCode, (Ptr{JV}, UInt8)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "ToJLString"
            unsafe_store!(
                fptr_ref,
                @cfunction(ToJLString, ErrorCode, (Ptr{JV}, TyList{UInt8})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "ToJLBool"
            unsafe_store!(
                fptr_ref,
                @cfunction(ToJLBool, ErrorCode, (Ptr{JV}, Bool)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "ToJLFloat64"
            unsafe_store!(
                fptr_ref,
                @cfunction(ToJLFloat64, ErrorCode, (Ptr{JV}, Float64)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "ToJLComplexF64"
            unsafe_store!(
                fptr_ref,
                @cfunction(ToJLComplexF64, ErrorCode, (Ptr{JV}, ComplexF64)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLStrVecWriteEltWithUTF8"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLStrVecWriteEltWithUTF8, ErrorCode, (JV, Int64, TyList{UInt8})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLStrVecGetEltNBytes"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLStrVecGetEltNBytes, ErrorCode, (Ptr{Int64}, JV, Int64)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLStrVecReadEltWithUTF8"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLStrVecReadEltWithUTF8, ErrorCode, (JV, Int64, TyList{UInt8})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLTypeToIdent"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLTypeToIdent, ErrorCode, (Ptr{Int64}, JV)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLTypeFromIdent"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLTypeFromIdent, ErrorCode, (Ptr{JV}, Int64)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLNew_F64Array"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLNew_F64Array, ErrorCode, (Ptr{JV}, TyList{Int64})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLNew_U64Array"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLNew_U64Array, ErrorCode, (Ptr{JV}, TyList{Int64})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLNew_U32Array"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLNew_U32Array, ErrorCode, (Ptr{JV}, TyList{Int64})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLNew_U8Array"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLNew_U8Array, ErrorCode, (Ptr{JV}, TyList{Int64})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLNew_I64Array"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLNew_I64Array, ErrorCode, (Ptr{JV}, TyList{Int64})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLNew_BoolArray"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLNew_BoolArray, ErrorCode, (Ptr{JV}, TyList{Int64})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLNew_ComplexF64Array"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLNew_ComplexF64Array, ErrorCode, (Ptr{JV}, TyList{Int64})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLNew_StringVector"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLNew_StringVector, ErrorCode, (Ptr{JV}, Int64)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLArray_Size"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLArray_Size, ErrorCode, (Ptr{Int64}, JV, Int64)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLArray_Rank"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLArray_Rank, ErrorCode, (Ptr{Int64}, JV)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLError_EnableBackTraceMsg"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLError_EnableBackTraceMsg, Nothing, (Bool,)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLError_HasBackTraceMsg"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLError_HasBackTraceMsg, UInt8, ()))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLError_FetchMsgSize"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLError_FetchMsgSize, ErrorCode, (Ptr{Int64},)))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLError_FetchMsgStr"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLError_FetchMsgStr, ErrorCode, (Ptr{JSym}, TyList{UInt8})))
            unsafe_store!(status_ref, true)
            return
        end
        if jname == "JLCommonTag"
            unsafe_store!(
                fptr_ref,
                @cfunction(JLCommonTag, UInt8, (JV,)))
            unsafe_store!(status_ref, true)
            return
        end
        unsafe_store!(status_ref, false)
    catch
        unsafe_store!(status_ref, false)
        return
    end
end

get_capi_getter() = @cfunction(get_capi, Cvoid, (Cstring, Ptr{Ptr{Cvoid}}, Ptr{Bool}))

precompile(get_capi_getter, ())
precompile(get_capi, (Cstring, Ptr{Ptr{Cvoid}}, Ptr{Bool}))
