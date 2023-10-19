to_cs_type(x::Type{Out{A}}) where A = "out " * to_cs_type(A)
to_cs_type(x::Type{Ptr{A}}) where A = to_cs_type(A) * "*"
to_cs_type(x::Type{JV}) = "JV.jv_t"
to_cs_type(x::Type{Int32}) = "int"
to_cs_type(x::Type{Float32}) = "float"
to_cs_type(x::Type{Int64}) = "long"
to_cs_type(x::Type{Float64}) = "double"
to_cs_type(x::Type{Bool}) = "byte"
to_cs_type(x::Type{Cvoid}) = "void"
to_cs_type(x::Type{TyList{A}}) where A = "JuliaCAPI.list_t<" * to_cs_type(A) * ">"
to_cs_type(x::Type{TyTuple{A, B}}) where {A, B} = "JuliaCAPI.tuple_t<$(to_cs_type(A)),$(to_cs_type(B))>"
to_cs_type(x::Type{JSym}) = "JSym.jsym_t"
to_cs_type(x::Type{UInt32}) = "uint"
to_cs_type(x::Type{UInt64}) = "ulong"
to_cs_type(x::Type{ComplexF64}) = "Complex<double>"
to_cs_type(x::Type{UInt8}) = "byte"
to_cs_type(x::Type{ErrorCode}) = "JuliaCAPI.ErrorCode"
to_cs_type(x::Type{Compare}) = "Compare"

function _gen_cs_api_binding_struct_field(ch, name::Symbol, ns::Signature)
    pars = join([to_cs_type.(ns.pars)..., to_cs_type(ns.ret)], ",")
    put!(ch, "internal delegate* unmanaged[Cdecl]<$pars> $name;")
end

function _gen_cs_api_binding_struct(ch)
    for (name, ns) in apis
        _gen_cs_api_binding_struct_field(ch, name, Signature(ns))
    end
end

_gen_cs_api_binding_struct() = Channel{String}() do ch
    _gen_cs_api_binding_struct(ch)
end

function gen_cs_api_binding_struct(ch)
    put!(ch, "internal unsafe struct julia_api_t")
    put!(ch, "{")
    for each in _gen_cs_api_binding_struct()
        put!(ch, "    " * each)
    end
    put!(ch, "")
    put!(ch, "    internal static void populateCAPI(julia_api_t* api, delegate* unmanaged[Cdecl]<byte*, nint*, ref byte, void> get_capi)")
    put!(ch, "    {")
    put!(ch, "        byte status = 0;")
    for (name, _) in apis
    put!(ch, "        fixed(byte* nameAsBytes = System.Text.Encoding.UTF8.GetBytes(\"$name\"))")
    put!(ch, "        {")
    put!(ch, "            get_capi(nameAsBytes, (nint*)&api->$name, ref status);")
    put!(ch, "            if (status == 0) throw new System.Exception(\"Failed to get $name\");")
    put!(ch, "            status = 0;")
    put!(ch, "        }")
    end
    put!(ch, "    }")
    put!(ch, "}")
end

gen_cs_api_binding_struct() = Channel{String}() do ch
    gen_cs_api_binding_struct(ch)
end
