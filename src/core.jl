const error_messages = Tuple{Symbol,String}[]

@noinline function produce_error!(e::Exception)
    @nospecialize e
    s = String(sprint(showerror, e))::String
    kind = nameof(typeof(e))::Symbol
    push!(error_messages, (kind, s))
    return nothing
end

@noinline function produce_error!(e::Exception, bt)
    @nospecialize e bt
    buff = IOBuffer()
    showerror(buff, e, bt)
    s = String(take!(buff))::String
    kind = nameof(typeof(e))::Symbol
    push!(error_messages, (kind, s))
    return nothing
end

const SHOW_JULIA_BACKTRACE = Ref{Bool}(false)

JLError_HasBackTraceMsg() = UInt8(SHOW_JULIA_BACKTRACE[])

function JLError_EnableBackTraceMsg(val::Bool)
    SHOW_JULIA_BACKTRACE[] = !iszero(val)
    return nothing
end

macro produce_error!(e)
    ex = quote
        if SHOW_JULIA_BACKTRACE[]
            produce_error!($(esc(e)), catch_backtrace())
        else
            produce_error!($(esc(e)))
        end
    end
    return ex
end

@noinline function first_error_size(sizeOut::Ptr{Int64})
    isempty(error_messages) && return false
    kind, s = error_messages[end]
    if sizeOut != C_NULL
        unsafe_store!(sizeOut, Int64(ncodeunits(s)))
    end
    return true
end

@noinline function consume_error!(kindOut::Ptr{JSym}, errMsgOut::TyList{UInt8})
    isempty(error_messages) && return false
    kindOut == C_NULL && return false
    errMsgOut == C_NULL && return false
    # 后进先出，保证总是获取到最新的错误消息
    kind, msg = pop!(error_messages)
    msgNBytes = ncodeunits(msg)
    errMsgOut.len < msgNBytes && return false

    unsafe_store!(kindOut, JSym(kind))
    GC.@preserve msg begin
        msgPtr = pointer(msg)
        unsafe_copyto!(errMsgOut.data, msgPtr, msgNBytes)
    end
    return true
end

function JLFreeFromMe(value::JV)
    JV_DEALLOC(value)
    return nothing
end

function JLEval(out::Ptr{JV}, module′::JV, code::TyList{UInt8})::ErrorCode
    try
        M = module′.ID == 0 ? Main : JV_LOAD(module′)::Module
        v = Base.eval(M, Meta.parseall(unsafe_string(code)))
        unsafe_store!(out, JV_ALLOC(v))
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLError_FetchMsgSize(out::Ptr{Int64})::ErrorCode
    first_error_size(out) && return OK
    return ERROR
end

const FetchJLErrorSize = JLError_FetchMsgSize

function JLError_FetchMsgStr(out::Ptr{JSym}, msgBuf::TyList{UInt8})::ErrorCode
    return consume_error!(out, msgBuf) ? OK : ERROR
end

const FetchJLError = JLError_FetchMsgStr

@noinline function _load_call_args(funcProxy::JV, argProxies::TyList{JV}, kwargProxies::TyList{TyTuple{JSym,JV}})
    func = JV_LOAD(funcProxy)::Any
    args = Any[JV_LOAD(unsafe_load(argProxies.data, i)) for i in 1:(argProxies.len)]
    kwargs = Dict{Symbol,Any}()
    for i in 1:(kwargProxies.len)
        kv = unsafe_load(kwargProxies.data, i)
        k = JSym_LOAD(kv.fst)
        v = JV_LOAD(kv.snd)
        kwargs[k] = v
    end
    return func, args, kwargs
end

@noinline function _barrier_call_f(f, args...; kwargs...)
    @nospecialize f, args, kwargs
    f(args...; kwargs...)
end

@noinline function _barrier_call_f_dot(f, args...; kwargs...)
    @nospecialize f, args, kwargs
    f.(args...; kwargs...)
end

@noinline function _barrier_call_f_a0(f)
    @nospecialize f
    f()
end

@noinline function _barrier_call_f_a1(f, arg)
    @nospecialize f, arg
    f(arg)
end

@noinline function _barrier_call_f_a2(f, arg1, arg2)
    @nospecialize f, arg1, arg2
    f(arg1, arg2)
end

@noinline function _barrier_call_f_a3(f, arg1, arg2, arg3)
    @nospecialize f, arg1, arg2, arg3
    f(arg1, arg2, arg3)
end


function JLCallImpl(
    out::Ptr{JV},
    funcProxy::JV,
    argProxies::TyList{JV},
    kwargProxies::TyList{TyTuple{JSym,JV}},
    dotcall::Bool=false,
)
    try
        func, args, kwargs = _load_call_args(funcProxy, argProxies, kwargProxies)
        ret = if dotcall
            _barrier_call_f_dot(func, args...; kwargs...)
        else
            if length(kwargs) == 0
                if length(args) == 0
                    _barrier_call_f_a0(Base.inferencebarrier(func))
                elseif length(args) == 1
                    _barrier_call_f_a1(Base.inferencebarrier(func), args[1])
                elseif length(args) == 2
                    _barrier_call_f_a2(Base.inferencebarrier(func), args[1], args[2])
                elseif length(args) == 3
                    _barrier_call_f_a3(Base.inferencebarrier(func), args[1], args[2], args[3])
                else
                    _barrier_call_f(Base.inferencebarrier(func), args...)
                end
            else
                _barrier_call_f(Base.inferencebarrier(func), args...; kwargs...)
            end
        end
        retProxy = JV_ALLOC(ret)
        unsafe_store!(out, retProxy)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLCall(
    out::Ptr{JV},
    funcProxy::JV,
    argProxies::TyList{JV},
    kwargProxies::TyList{TyTuple{JSym,JV}},
)::ErrorCode
    return JLCallImpl(out, funcProxy, argProxies, kwargProxies, false)
end

precompile(JLCall, (Ptr{JV}, JV, TyList{JV}, TyList{TyTuple{JSym,JV}}))

function JLDotCall(
    out::Ptr{JV},
    funcProxy::JV,
    argProxies::TyList{JV},
    kwargProxies::TyList{TyTuple{JSym,JV}},
)::ErrorCode
    return JLCallImpl(out, funcProxy, argProxies, kwargProxies, true)
end

precompile(JLDotCall, (Ptr{JV}, JV, TyList{JV}, TyList{TyTuple{JSym,JV}}))

function JSymToJV(symCache::JSym)::JV
    symCache.ID == 0 && return JV()
    sym = JSym_LOAD(symCache)
    return JV_ALLOC(sym)
end

function JLTypeOf(proxy::JV)::JV
    v = JV_LOAD(proxy)
    return JV_ALLOC(typeof(v))
end

function JLTypeOfAsTypeSlot(proxy::JV)::Int64
    v = JV_LOAD(proxy)
    return JTypeToIdent(typeof(v))
end

function JLIsInstanceWithTypeSlot(proxy::JV, slot::Int64)::Bool
    v = JV_LOAD(proxy)
    t = JTypeFromIdent(slot)
    return isa(v, t)::Bool
end

function JLCompare(out::Ptr{Bool}, cmp::Compare, a::JV, b::JV)::ErrorCode
    try
        a′ = JV_LOAD(a)
        b′ = JV_LOAD(b)
        if cmp == SEQ
            unsafe_store!(out, a′ === b′)
            return OK
        elseif cmp == SNE
            unsafe_store!(out, a′ !== b′)
            return OK
        elseif cmp == EQ
            unsafe_store!(out, a′ == b′)
            return OK
        elseif cmp == NE
            unsafe_store!(out, a′ != b′)
            return OK
        elseif cmp == LT
            unsafe_store!(out, a′ < b′)
            return OK
        elseif cmp == LE
            unsafe_store!(out, a′ <= b′)
            return OK
        elseif cmp == GT
            unsafe_store!(out, a′ > b′)
            return OK
        elseif cmp == GE
            unsafe_store!(out, a′ >= b′)
            return OK
        else
            error("Invalid comparison operator $cmp")
        end
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetProperty(out::Ptr{JV}, self::JV, property::JSym)::ErrorCode
    try
        self′ = JV_LOAD(self)
        property′ = JSym_LOAD(property)
        propVal = getproperty(Base.inferencebarrier(self′), property′)
        unsafe_store!(out, JV_ALLOC(propVal))
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLSetProperty(self::JV, property::JSym, value::JV)::ErrorCode
    try
        self′ = JV_LOAD(self)
        property′ = JSym_LOAD(property)
        value′ = JV_LOAD(value)
        setproperty!(Base.inferencebarrier(self′), property′, Base.inferencebarrier(value′))
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLHasProperty(out::Ptr{Bool}, self::JV, property::JSym)::ErrorCode
    try
        self′ = JV_LOAD(self)
        property′ = JSym_LOAD(property)
        test = hasproperty(Base.inferencebarrier(self′), property′)
        unsafe_store!(out, test)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetIndex(out::Ptr{JV}, self::JV, indices::TyList{JV})::ErrorCode
    try
        self′ = JV_LOAD(self)
        indices′ = [JV_LOAD(unsafe_load(indices.data, i)) for i in 1:(indices.len)]
        indexVal = getindex(Base.inferencebarrier(self′), indices′...)
        unsafe_store!(out, JV_ALLOC(indexVal))
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetIndexI(out::Ptr{JV}, self::JV, index::Int64)::ErrorCode
    try
        self′ = JV_LOAD(self)
        indexVal = getindex(Base.inferencebarrier(self′), index)
        unsafe_store!(out, JV_ALLOC(indexVal))
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLSetIndex(self::JV, indices::TyList{JV}, value::JV)::ErrorCode
    try
        self′ = JV_LOAD(self)
        value′ = JV_LOAD(value)
        indices′ = [JV_LOAD(unsafe_load(indices.data, i)) for i in 1:(indices.len)]
        setindex!(Base.inferencebarrier(self′), Base.inferencebarrier(value′), indices′...)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLSetIndexI(self::JV, index::Int64, value::JV)::ErrorCode
    try
        self′ = JV_LOAD(self)
        value′ = JV_LOAD(value)
        setindex!(Base.inferencebarrier(self′), Base.inferencebarrier(value′), index)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetSymbol(out::Ptr{JSym}, value::JV, doCast::Bool)::ErrorCode
    try
        value′ = JV_LOAD(value)::Symbol
        v = doCast ? convert(Symbol, value′) : (value′::Symbol)
        unsafe_store!(out, JSym(v))
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetBool(out::Ptr{Bool}, value::JV, doCast::Bool)::ErrorCode
    try
        value′ = JV_LOAD(value)
        v = doCast ? convert(Bool, value′) : (value′::Bool)
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetUInt8(out::Ptr{UInt8}, value::JV, doCast::Bool)::ErrorCode
    try
        value′ = JV_LOAD(value)
        v = doCast ? convert(UInt8, value′) : (value′::UInt8)
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetUInt16(out::Ptr{UInt16}, value::JV, doCast::Bool)::ErrorCode
    try
        value′ = JV_LOAD(value)
        v = doCast ? convert(UInt16, value′) : (value′::UInt16)
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetUInt32(out::Ptr{UInt32}, value::JV, doCast::Bool)::ErrorCode
    try
        value′ = JV_LOAD(value)
        v = doCast ? convert(UInt32, value′) : (value′::UInt32)
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetUInt64(out::Ptr{UInt64}, value::JV, doCast::Bool)::ErrorCode
    try
        value′ = JV_LOAD(value)
        v = doCast ? convert(UInt64, value′) : (value′::UInt64)
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetInt32(out::Ptr{Int32}, value::JV, doCast::Bool)::ErrorCode
    try
        value′ = JV_LOAD(value)
        v = doCast ? convert(Int32, value′) : (value′::Int32)
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetInt64(out::Ptr{Int64}, value::JV, doCast::Bool)::ErrorCode
    try
        value′ = JV_LOAD(value)
        v = doCast ? convert(Int64, value′) : (value′::Int64)
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetInt16(out::Ptr{Int16}, value::JV, doCast::Bool)::ErrorCode
    try
        value′ = JV_LOAD(value)
        v = doCast ? convert(Int16, value′) : (value′::Int16)
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetInt8(out::Ptr{Int8}, value::JV, doCast::Bool)::ErrorCode
    try
        value′ = JV_LOAD(value)
        v = doCast ? convert(Int8, value′) : (value′::Int8)
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetSingle(out::Ptr{Float32}, value::JV, doCast::Bool)::ErrorCode
    try
        value′ = JV_LOAD(value)
        v = doCast ? convert(Float32, value′) : (value′::Float32)
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetDouble(out::Ptr{Float64}, value::JV, doCast::Bool)::ErrorCode
    try
        value′ = JV_LOAD(value)
        v = doCast ? convert(Float64, value′) : (value′::Float64)
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetComplexF64(out::Ptr{ComplexF64}, value::JV, doCast::Bool)::ErrorCode
    try
        value′ = JV_LOAD(value)
        v = doCast ? convert(ComplexF64, value′) : (value′::ComplexF64)
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetComplexF32(out::Ptr{ComplexF32}, value::JV, doCast::Bool)::ErrorCode
    try
        value′ = JV_LOAD(value)
        v = doCast ? convert(ComplexF32, value′) : (value′::ComplexF32)
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetUTF8String(out::TyList{UInt8}, value::JV)::ErrorCode
    try
        v = JV_LOAD(value)::String
        len = ncodeunits(v)
        out.len < len && return ERROR
        GC.@preserve v begin
            unsafe_copyto!(out.data, pointer(v), len)
        end
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLGetArrayPointer(dataOut::Ptr{Ptr{UInt8}}, lenOut::Ptr{Int64}, array::JV)::ErrorCode
    try
        a = JV_LOAD(array)
        (len, p) = _array_pointer_barrier(Base.inferencebarrier(a))
        unsafe_store!(dataOut, p)
        unsafe_store!(lenOut, len)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function ToJLString(out::Ptr{JV}, buf::TyList{UInt8})::ErrorCode
    try
        v = JV_ALLOC(unsafe_string(buf.data, buf.len))
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function _ToJLNumber(out::Ptr{JV}, value::Number)::ErrorCode
    try
        v = JV_ALLOC(value)
        unsafe_store!(out, v)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

ToJLInt64(out::Ptr{JV}, value::Int64)::ErrorCode = _ToJLNumber(out, value)
ToJLInt32(out::Ptr{JV}, value::Int32)::ErrorCode = _ToJLNumber(out, value)
ToJLInt16(out::Ptr{JV}, value::Int16)::ErrorCode = _ToJLNumber(out, value)
ToJLInt8(out::Ptr{JV}, value::Int8)::ErrorCode = _ToJLNumber(out, value)
ToJLUInt64(out::Ptr{JV}, value::UInt64)::ErrorCode = _ToJLNumber(out, value)
ToJLUInt32(out::Ptr{JV}, value::UInt32)::ErrorCode = _ToJLNumber(out, value)
ToJLUInt16(out::Ptr{JV}, value::UInt16)::ErrorCode = _ToJLNumber(out, value)
ToJLUInt8(out::Ptr{JV}, value::UInt8)::ErrorCode = _ToJLNumber(out, value)
ToJLFloat64(out::Ptr{JV}, value::Float64)::ErrorCode = _ToJLNumber(out, value)
ToJLFloat32(out::Ptr{JV}, value::Float32)::ErrorCode = _ToJLNumber(out, value)
ToJLComplexF64(out::Ptr{JV}, value::ComplexF64)::ErrorCode = _ToJLNumber(out, value)
ToJLComplexF32(out::Ptr{JV}, value::ComplexF32)::ErrorCode = _ToJLNumber(out, value)
ToJLBool(out::Ptr{JV}, value::Bool)::ErrorCode = _ToJLNumber(out, value)

function JVToJSym(out::Ptr{JSym}, value::JV)::ErrorCode
    try
        v = JV_LOAD(value)::Symbol
        unsafe_store!(out, JSym(v))
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JSymFromString(out::Ptr{JSym}, value::TyList{UInt8})::ErrorCode
    try
        s = unsafe_string(value)
        v = Symbol(s)
        unsafe_store!(out, JSym(v))
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLStrVecWriteEltWithUTF8(self::JV, i::Int64, value::TyList{UInt8})::ErrorCode
    try
        s = JV_LOAD(self)::Vector{String}
        s[i] = unsafe_string(value)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLStrVecGetEltNBytes(out::Ptr{Int64}, self::JV, i::Int64)::ErrorCode
    try
        s = JV_LOAD(self)::Vector{String}
        unsafe_store!(out, ncodeunits(s[i]))
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLStrVecReadEltWithUTF8(self::JV, i::Int64, value::TyList{UInt8})::ErrorCode
    try
        s = JV_LOAD(self)::Vector{String}
        e = s[i]
        value.len == ncodeunits(e) || error("length mismatch")
        GC.@preserve e begin
            unsafe_copyto!(value.data, pointer(e), value.len)
        end
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLTypeToIdent(out::Ptr{Int64}, value::JV)::ErrorCode
    try
        t = JV_LOAD(value)::Type
        unsafe_store!(out, JTypeToIdent(t))
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLTypeFromIdent(out::Ptr{JV}, value::Int64)::ErrorCode
    try
        t = JTypeFromIdent(value)
        unsafe_store!(out, JV_ALLOC(t))
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end


function _create_jl_array(::Type{T}, dims::TyList{Int64})::JV where {T}
    len_dims = length(dims)
    if len_dims == 1
        return JV_ALLOC(Vector{T}(undef, dims[1]))
    elseif len_dims == 2
        return JV_ALLOC(Matrix{T}(undef, dims[1], dims[2]))
    elseif len_dims == 3
        return JV_ALLOC(Array{T,3}(undef, dims[1], dims[2], dims[3]))
    else
        N = len_dims
        JV_ALLOC(Array{T, N}(undef, ntuple(i->dims[i], N)))
    end
end

function _JLNew_TArray(::Type{T}, out::Ptr{JV}, dims::TyList{Int64})::ErrorCode where {T}
    try
        n = dims.len
        n == 0 && error("array should have at least one dimension")
        jv = _create_jl_array(T, dims)
        unsafe_store!(out, jv)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

JLNew_U64Array(out::Ptr{JV}, dims::TyList{Int64})::ErrorCode = _JLNew_TArray(UInt64, out, dims)
JLNew_U32Array(out::Ptr{JV}, dims::TyList{Int64})::ErrorCode = _JLNew_TArray(UInt32, out, dims)
JLNew_U16Array(out::Ptr{JV}, dims::TyList{Int64})::ErrorCode = _JLNew_TArray(UInt16, out, dims)
JLNew_U8Array(out::Ptr{JV}, dims::TyList{Int64})::ErrorCode = _JLNew_TArray(UInt8, out, dims)
JLNew_I64Array(out::Ptr{JV}, dims::TyList{Int64})::ErrorCode = _JLNew_TArray(Int64, out, dims)
JLNew_I32Array(out::Ptr{JV}, dims::TyList{Int64})::ErrorCode = _JLNew_TArray(Int32, out, dims)
JLNew_I16Array(out::Ptr{JV}, dims::TyList{Int64})::ErrorCode = _JLNew_TArray(Int16, out, dims)
JLNew_I8Array(out::Ptr{JV}, dims::TyList{Int64})::ErrorCode = _JLNew_TArray(Int8, out, dims)
JLNew_BoolArray(out::Ptr{JV}, dims::TyList{Int64})::ErrorCode = _JLNew_TArray(Bool, out, dims)
JLNew_ComplexF64Array(out::Ptr{JV}, dims::TyList{Int64})::ErrorCode = _JLNew_TArray(ComplexF64, out, dims)
JLNew_ComplexF32Array(out::Ptr{JV}, dims::TyList{Int64})::ErrorCode = _JLNew_TArray(ComplexF32, out, dims)
JLNew_F64Array(out::Ptr{JV}, dims::TyList{Int64})::ErrorCode = _JLNew_TArray(Float64, out, dims)
JLNew_F32Array(out::Ptr{JV}, dims::TyList{Int64})::ErrorCode = _JLNew_TArray(Float32, out, dims)

function JLNew_StringVector(out::Ptr{JV}, length::Int64)::ErrorCode
    try
        str_vec = Vector{String}(undef, length)
        jv = JV_ALLOC(str_vec)
        unsafe_store!(out, jv)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLArray_Size(out::Ptr{Int64}, self::JV, i::Int64)::ErrorCode
    try
        a = JV_LOAD(self)
        nd = @ccall jl_array_size(a::Any, i::Cint)::Int32
        unsafe_store!(out, Int64(nd))
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

function JLArray_Rank(out::Ptr{Int64}, self::JV)::ErrorCode
    try
        a = JV_LOAD(self)
        n = @ccall jl_array_rank(a::Any)::Csize_t
        unsafe_store!(out, Int64(n))
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

# JV is like an unique_ptr,
# when trying to shared it to another language,
# we need to share it and allocate a new JV object in object pool.
function JLNewOwner(out::Ptr{JV}, self::JV)::ErrorCode
    try
        a = JV_LOAD(self)
        a′ = JV_ALLOC(a)
        unsafe_store!(out, a′)
        return OK
    catch e
        @produce_error!(e)
        return ERROR
    end
end

include("data_tags.jl")
