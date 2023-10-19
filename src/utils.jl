function _array_pointer_barrier(x)
    T = typeof(x)
    return error(
        "Try passing data of julia object ($(T)) that is not a raw array using TyJuliaCAPI"
    )
end

function _array_pointer_barrier(x::Array{T})::Tuple{Int64,Ptr{UInt8}} where {T}
    Base.isbitstype(T) || error("Cannot pass data of non-bitstype array using TyJuliaCAPI")
    Base.isbitsunion(T) && error("Cannot pass array of array bitsunion using TyJuliaCAPI")
    return (Int64(length(x)), reinterpret(Ptr{UInt8}, pointer(x)))
end
