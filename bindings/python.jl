using JSON3
to_py_type(x::Type{Out{A}}) where A = "POINTER(" * to_py_type(A) * ")"
to_py_type(x::Type{Ptr{A}}) where A = "POINTER(" * to_py_type(A) * ")"
to_py_type(x::Type{JV}) = "opaque64"
to_py_type(x::Type{Int8}) = "c_int8"
to_py_type(x::Type{Int16}) = "c_int16"
to_py_type(x::Type{Int32}) = "c_int32"
to_py_type(x::Type{Float32}) = "c_float"
to_py_type(x::Type{Int64}) = "c_int64"
to_py_type(x::Type{Float64}) = "c_double"
to_py_type(x::Type{Bool}) = "c_uint8"
to_py_type(x::Type{Cvoid}) = "None"
to_py_type(x::Type{TyList{A}}) where A = "NList_" * to_py_type(A)
to_py_type(x::Type{TyTuple{A, B}}) where {A, B} = "NTuple_$(to_py_type(A))__$(to_py_type(B))"
to_py_type(x::Type{JSym}) = "opaque64"
to_py_type(x::Type{UInt16}) = "c_uint16"
to_py_type(x::Type{UInt32}) = "c_uint32"
to_py_type(x::Type{UInt64}) = "c_uint64"
to_py_type(x::Type{ComplexF64}) = "c_complex64"
to_py_type(x::Type{ComplexF32}) = "c_complex32"
to_py_type(x::Type{UInt8}) = "c_uint8"
to_py_type(x::Type{ErrorCode}) = "c_uint8"
to_py_type(x::Type{Compare}) = "c_uint8"

function _gen_py_api_binding_struct_field(ch, name::Symbol, ns::Signature)
    pars = join(to_py_type.(ns.pars), ",")
    res = to_py_type(ns.ret)
    put!(ch, "$name = load_tyjuliacapi(libjulia, \"$name\", $res, $pars)")
end

function _gen_py_api_binding_struct(ch)
    for (name, ns) in apis
        _gen_py_api_binding_struct_field(ch, name, Signature(ns))
    end
end

_gen_py_api_binding_struct() = Channel{String}() do ch
    _gen_py_api_binding_struct(ch)
end

function gen_py_api_binding_struct(ch)
    put!(ch, "from ctypes import * # type: ignore")
    put!(ch, "from .extra_types import * # type: ignore")
    put!(ch, "from .init import libjulia # type: ignore")
    put!(ch, "")
    put!(ch, "")

    exports = String[]

    for (name, _) in apis
        push!(exports, string(name))
    end
    for each in _gen_py_api_binding_struct()
        put!(ch, each)
    end

    put!(ch, "")

    put!(ch, "__all__ = " * JSON3.write(exports))
end

gen_py_api_binding_struct() = Channel{String}() do ch
    gen_py_api_binding_struct(ch)
end
