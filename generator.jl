import TyJuliaCAPI
import TyJuliaCAPI: Compare, ErrorCode, JV, JSym, TyTuple, TyList
import PrettyPrint
using MLStyle

struct Out{T}
    ref::Ptr{T}
end

const NativeChar = UInt8

struct Signature{N}
    pars::NTuple{N, Type}
    ret::Type
end

struct NamedSignature{N}
    pars::NTuple{N, Pair{Symbol,Type}}
    ret::Type
end

Signature(typed::NamedSignature) = Signature(map(x -> x.second, typed.pars), typed.ret)

function _argument(arg)
    @match arg begin
        :($n :: $t) => :(Pair{Symbol,Type}($(QuoteNode(n)), $t))
    end
end

function _signature(call)
    @match call begin
        :($f($(args...)) :: $b) =>
            let args = Expr(:tuple, _argument.(args)...)
                :($(QuoteNode(f)) => NamedSignature($args, $b))
            end
    end
end

macro signature(call)
    esc(_signature(call))
end

include("apis.jl")

to_ptr_type(::Type{Out{A}}) where A = Ptr{to_ptr_type(A)}
to_ptr_type(a) = a

struct Signature{N}
    pars::NTuple{N, Type}
    ret::Type
end

to_ptr_type(sig::Signature) = Signature(to_ptr_type.(sig.pars), sig.ret)

function get_sig(f)
    m = methods(f)[1]
    pars = Tuple(m.sig.parameters[2:end])
    ret = Base.return_types(f, pars)[1]
    Signature(pars, ret)
end

function validate_api!()
    cur = @__MODULE__
    for (name, typed_sig) in apis
        api_f = getfield(TyJuliaCAPI, name)
        sig_f = get_sig(api_f)
        sig = Signature(typed_sig)
        sig_f == to_ptr_type(sig) ||
            error("$name sig mismatch: $sig_f != $sig")
    end
end

function gen_cfunc_maker(name, sig::Signature)
    sig = to_ptr_type(sig)
    "@cfunction($name, $(sig.ret), $(sig.pars))"
end

function _gen_get_api(ch)
    for (name, typed_sig) in apis
        put!(ch, "if jname == \"$name\"")
        put!(ch, "    unsafe_store!(")
        put!(ch, "    " * "    " * "fptr_ref,")
        put!(ch, "    " * "    " * gen_cfunc_maker(name, Signature(typed_sig)) * ")")
        put!(ch, "    unsafe_store!(status_ref, true)")
        put!(ch, "    return")
        put!(ch, "end")
    end
end

_gen_get_api() = Channel{String}() do ch
    _gen_get_api(ch)
end

function gen_get_api(ch)
    put!(ch, "function get_capi(name::Cstring, fptr_ref::Ptr{Ptr{Cvoid}}, status_ref::Ptr{Bool})")
    put!(ch, "    jname = unsafe_string(name)")
    put!(ch, "    try")
    for each in _gen_get_api()
        put!(ch, "    " * "    " * each)
    end
    put!(ch, "        unsafe_store!(status_ref, false)")
    put!(ch, "    catch")
    put!(ch, "        unsafe_store!(status_ref, false)")
    put!(ch, "        return")
    put!(ch, "    end")
    put!(ch, "end")
    put!(ch, "")
    put!(ch, "get_capi_getter() = @cfunction(get_capi, Cvoid, (Cstring, Ptr{Ptr{Cvoid}}, Ptr{Bool}))")
    put!(ch, "")
    put!(ch, "precompile(get_capi_getter, ())")
    put!(ch, "precompile(get_capi, (Cstring, Ptr{Ptr{Cvoid}}, Ptr{Bool}))")
end

gen_get_api() = Channel{String}() do ch
    gen_get_api(ch)
end

validate_api!()

open("src/exportc.jl", "w") do io
    println(io, "# This file is generated. Do not modify it directly.")
    for each in gen_get_api()
        println(io, each)
    end
end

open("src/api_names.jl", "w") do io
    println(io, "# This file is generated. Do not modify it directly.")
    println(io, "APINames = ")
    PrettyPrint.pprintln(io, [name for (name, _) in apis])
end

cs_binding_path = get(ENV, "CS_BINDING", "")
cpp_binding_dir = get(ENV, "CPP_BINDING_DIR", "")
deno_binding_path = get(ENV, "DENO_BINDING", "")
py_binding_path = get(ENV, "PY_BINDING", "")

if !isempty(cs_binding_path)
    include("bindings/csharp.jl")

    open(cs_binding_path, "w") do io
        println(io, "// This file is generated. Do not modify it directly.")
        for each in gen_cs_api_binding_struct()
            println(io, each)
        end
    end
end


if !isempty(cpp_binding_dir)
    include("bindings/documentation.jl")

    open(joinpath(cpp_binding_dir, "tyjuliacapi-base.hpp"), "w") do io
        println(io, "// This file is generated. Do not modify it directly.")
        for each in gen_doc_api_binding_struct(_cpp_source)
            println(io, each)
        end
    end

    open(joinpath(cpp_binding_dir, "tyjuliacapi-docs.hpp"), "w") do io
        println(io, "// This file is generated. Do not modify it directly.")
        println(io, "// This file is for documentation purpose only. Do not include it for compilation.")
        for each in gen_doc_api_binding_struct(_cpp_header)
            println(io, each)
        end
    end
end

if !isempty(deno_binding_path)
    include("bindings/deno.jl")

    open(deno_binding_path, "w") do io
        for each in gen_deno_api_binding_struct()
            println(io, each)
        end
    end
end


if !isempty(py_binding_path)
    include("bindings/python.jl")

    open(py_binding_path, "w") do io
        println(io, "# This file is generated. Do not modify it directly.")
        for each in gen_py_api_binding_struct()
            println(io, each)
        end
    end
end
