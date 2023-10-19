module TyJuliaCAPI
export produce_error!, consume_error!, first_error_size
export TyList, TyTuple, JV, JSym
export JV_ALLOC, JV_DEALLOC, JV_LOAD
export JSym, JSym_LOAD
export ErrorCode, Compare, OK, ERROR

export JLEval, JLFreeFromMe, FetchJLErrorSize, FetchJLError
export JLCall, JLDotCall, JSymToJV, JLTypeOf, JLCompare, JLArray_Size, JLArray_Rank

export JLHasProperty, JLGetProperty, JLSetProperty, JLGetIndex, JLSetIndex
export JLGetSymbol, JLGetBool, JLGetUInt8, JLGetUInt32, JLGetUInt64
export JLGetInt32, JLGetInt64, JLGetSingle, JLGetDouble, JLGetUTF8String
export JLGetArrayPointer, JSymFromString
export ToJLString, ToJLInt64, ToJLUInt32, ToJLUInt64, ToJLFloat64, ToJLComplexF64
export PopulateCAPI
export TyJuliaCAPI_Base, TyJuliaCAPI_Object, TyJuliaCAPI_FromJ, TyJuliaCAPI_ToJ
export JLError_EnableBackTraceMsg, JLError_DisableBackTraceMsg
export JLTypeOfAsTypeSlot, JLIsInstanceWithTypeSlot
export JLCommonTag

Base.@kwdef struct TyJuliaCAPI_Base
    JLFreeFromMe::Ptr{Cvoid}
    JLEval::Ptr{Cvoid}
    FetchJLErrorSize::Ptr{Cvoid}
    FetchJLError::Ptr{Cvoid}
    JLEnable_BackTrace::Ptr{Cvoid}
    JLDisable_BackTrace::Ptr{Cvoid}
end

Base.@kwdef struct TyJuliaCAPI_Object
    JSymToJV::Ptr{Cvoid}
    JLTypeOf::Ptr{Cvoid}

    JLCall::Ptr{Cvoid}
    JLDotCall::Ptr{Cvoid}
    JLCompare::Ptr{Cvoid}
    JLGetProperty::Ptr{Cvoid}
    JLSetProperty::Ptr{Cvoid}
    JLHasProperty::Ptr{Cvoid}
    JLGetIndex::Ptr{Cvoid}
    JLSetIndex::Ptr{Cvoid}
end

Base.@kwdef struct TyJuliaCAPI_FromJ
    JLGetSymbol::Ptr{Cvoid}
    JLGetBool::Ptr{Cvoid}
    JLGetUInt8::Ptr{Cvoid}
    JLGetUInt32::Ptr{Cvoid}
    JLGetUInt64::Ptr{Cvoid}
    JLGetInt32::Ptr{Cvoid}
    JLGetInt64::Ptr{Cvoid}
    JLGetSingle::Ptr{Cvoid}
    JLGetDouble::Ptr{Cvoid}
    JLGetUTF8String::Ptr{Cvoid}
    JLGetArrayPointer::Ptr{Cvoid}
end

Base.@kwdef struct TyJuliaCAPI_ToJ
    JSymFromString::Ptr{Cvoid}
    ToJLString::Ptr{Cvoid}
    ToJLInt64::Ptr{Cvoid}
    ToJLUInt64::Ptr{Cvoid}
    ToJLUInt32::Ptr{Cvoid}
    ToJLCdouble::Ptr{Cvoid}
    ToJLComplexF64::Ptr{Cvoid}
end

include("utils.jl")
include("types.jl")
include("core.jl")
include("api_names.jl")
include("exportc.jl")

macro testset(a, ex)
    esc(ex)
end

macro test(ex)
    esc(ex)
end

let
    include("./run.jl")
end

end # module
