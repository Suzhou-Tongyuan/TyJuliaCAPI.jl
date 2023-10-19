Base.@enum ErrorCode::UInt8 begin
    OK = 0
    ERROR = 1
end

Base.@enum Compare::UInt8 begin
    SEQ = 0
    SNE = 1
    EQ = 2
    NE = 3
    LT = 4
    LE = 5
    GT = 6
    GE = 7
end

@assert sizeof(Bool) == sizeof(UInt8) "Unknown architecture that doesn't use 8-bit for Bool"

const JVPool = Any[]
const UnusedPoolSlots = Int64[]

Base.@kwdef struct JV
    ID::Int64 = 0
end

function JV_ALLOC(@nospecialize(x::Any))
    if isempty(UnusedPoolSlots)
        push!(JVPool, x)
        return JV(length(JVPool))
    else
        id = pop!(UnusedPoolSlots)
        JVPool[id] = x
        return JV(id)
    end
end

function JV_DEALLOC(x::JV)
    x.ID == 0 && return nothing
    push!(UnusedPoolSlots, x.ID)
    JVPool[x.ID] = nothing
    return nothing
end

@noinline function JV_LOAD(x::JV)
    return JVPool[x.ID]
end

Base.@kwdef struct JSym
    ID::Int64 = 0
end

const JSymCache = Base.IdDict{Symbol,JSym}()
const JSymPool = Symbol[]

function JSym(x::Symbol)
    get!(JSymCache, x) do
        push!(JSymPool, x)
        return JSym(length(JSymPool))
    end
end

@noinline function JSym_LOAD(x::JSym)
    return JSymPool[x.ID]
end

const JTypeCache = Base.IdDict{Type, Int64}()
const JTypeSlots = Type[]

function JTypeToIdent(x::Type)
    get!(JTypeCache, x) do
        push!(JTypeSlots, x)
        return Int64(length(JTypeSlots))
    end
end

function JTypeFromIdent(x::Int64)
    if x == 0
        return Any
    else
        return JTypeSlots[x]
    end
end

struct TyTuple{L,R}
    fst::L
    snd::R
end

struct TyList{T}
    len::Int64
    data::Ptr{T}
end

function Base.length(lst::TyList{T}) where T
    return lst.len
end

function Base.getindex(lst::TyList{T}, i::Integer) where T
    if i < 1 || i > lst.len
        throw(BoundsError(lst, i))
    end
    return unsafe_load(lst.data, i)
end

function Base.setindex!(lst::TyList{T}, x::T, i::Int) where T
    if i < 1 || i > lst.len
        throw(BoundsError(lst, i))
    end
    return unsafe_store!(lst.data, x, i)
end

function Base.unsafe_string(lst::TyList{UInt8})
    return unsafe_string(lst.data, lst.len)
end

function TyList(x::String)::TyList{UInt8}
    return TyList(length(x), pointer(x))
end

function __init__()
    empty!(JVPool)
    empty!(UnusedPoolSlots)
    empty!(JSymCache)
    return empty!(JSymPool)
end
