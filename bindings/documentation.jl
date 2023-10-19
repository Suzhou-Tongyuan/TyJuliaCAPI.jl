to_doc_type(x::Type{Out{A}}) where A = "/* out */" * to_doc_type(A) * "*"
to_doc_type(x::Type{Ptr{A}}) where A = to_doc_type(A) * "*"
to_doc_type(x::Type{JV}) = "JV"
to_doc_type(x::Type{Int32}) = "int32_t"
to_doc_type(x::Type{Float32}) = "float"
to_doc_type(x::Type{Int64}) = "int64_t"
to_doc_type(x::Type{Float64}) = "double"
to_doc_type(x::Type{Bool}) = "bool8_t"
to_doc_type(x::Type{Cvoid}) = "void"
to_doc_type(x::Type{TyList{A}}) where A = "SList<" * to_doc_type(A) * ">"
to_doc_type(x::Type{TyTuple{A, B}}) where {A, B} = "STuple<$(to_doc_type(A)),$(to_doc_type(B))>"
to_doc_type(x::Type{JSym}) = "JSym"
to_doc_type(x::Type{UInt32}) = "uint32_t"
to_doc_type(x::Type{UInt64}) = "uint64_t"
to_doc_type(x::Type{ComplexF64}) = "complex_t"
to_doc_type(x::Type{UInt8}) = "uint8_t"
to_doc_type(x::Type{ErrorCode}) = "ErrorCode"
to_doc_type(x::Type{Compare}) = "Compare"

function _cpp_header(ch, name::Symbol, ns::NamedSignature)
    argstr = join([to_doc_type(p) * " " * string(n) for (n, p) in ns.pars], ", ")
    retstr = to_doc_type(ns.ret)
    put!(ch, "$retstr $name($argstr);")
end

function _cpp_source(ch, name::Symbol, ns::NamedSignature)
    argstr = join([to_doc_type(p) * " " * string(n) for (n, p) in ns.pars], ", ")
    retstr = to_doc_type(ns.ret)
    put!(ch, "")
    put!(ch, "$retstr (*_fptr_$(name))($argstr);")
    put!(ch, "$retstr $name($argstr) {")
    args = join([string(n) for (n, p) in ns.pars], ", ")
    put!(ch, "    return _fptr_$(name)($(args));")
    put!(ch, "}")
end

function _gen_doc_api_binding_struct(f, ch)
    for (name, ns) in apis
        f(ch, name, ns)
    end

    put!(ch, "")

    if f !== _cpp_header
        put!(ch, "typedef void (*_get_capi_t)(const char* name, void** funcref,  bool8_t* status_ref);");
        put!(ch, "DLLEXPORT bool8_t library_init(_get_capi_t get_capi) {")
        put!(ch, "    bool8_t status;")
        for (name, ns) in apis
            put!(ch, "    get_capi(\"$(name)\", (void**)&_fptr_$(name), &status);")
            put!(ch, "    if (!status) {")
            put!(ch, "        printf(\"Failed to load $(name)\\n\");")
            put!(ch, "        return false;")
            put!(ch, "    }")
        end
        put!(ch, "    return true;")
        put!(ch, "}")
    end
end

_gen_doc_api_binding_struct(f) = Channel{String}() do ch
    _gen_doc_api_binding_struct(f, ch)
end

gen_doc_api_binding_struct(f) = Channel{String}() do ch
    put!(ch, "#include \"tyjuliacapi-types.hpp\"")
    put!(ch, "")
    _gen_doc_api_binding_struct(f, ch)
end