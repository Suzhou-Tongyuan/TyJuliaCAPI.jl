to_denoc_type(x::Type{Out{A}}) where A = "buffer"
to_denoc_type(x::Type{Ptr{A}}) where A = "buffer"
to_denoc_type(x::Type{JV}) = "i64" # slot
to_denoc_type(x::Type{Int32}) = "i32"
to_denoc_type(x::Type{Float32}) = "f32"
to_denoc_type(x::Type{Int64}) = "i64"
to_denoc_type(x::Type{Float64}) = "f64"
to_denoc_type(x::Type{Bool}) = "u8"
to_denoc_type(x::Type{Cvoid}) = "void"
to_denoc_type(x::Type{JSym}) = "i64" # slot
to_denoc_type(x::Type{UInt32}) = "u32"
to_denoc_type(x::Type{UInt64}) = "u64"
to_denoc_type(x::Type{UInt8}) = "u8"
to_denoc_type(x::Type{ErrorCode}) = "u8"
to_denoc_type(x::Type{Compare}) = "u8"
to_denoc_type(x::Type{TyTuple{A, B}}) where {A, B} = Dict(
    "struct" => [
        to_denoc_type(A),
        to_denoc_type(B),
    ]
)

to_denoc_type(x::Type{ComplexF64}) = Dict(
    "struct" => [
        "f64",
        "f64"
    ]
)

to_denoc_type(x::Type{TyList{A}}) where A = Dict(
    "struct" => String[
        "i64",
        "buffer"
    ]
)

function to_spec(ns::NamedSignature)
    return Dict(
        "parameters" => Any[ to_denoc_type(p) for (n, p) in ns.pars ],
        "result" => to_denoc_type(ns.ret)
    )
end

function _gen_deno_api_binding_struct()
    bindings = Dict(
        [string(name) => to_spec(ns) for (name, ns) in apis]
    )
    bindings["library_init"] = Dict(
        "parameters" => ["u64"],
        "result" => "u8",
    )
    return bindings
end

using JSON3

gen_deno_api_binding_struct() = Channel{String}() do ch
    local io = IOBuffer()
    local binding = JSON3.pretty(io, _gen_deno_api_binding_struct())
    binding = String(take!(io))
    binding = join([ string("           ", line) for line in split(binding, "\n") ], "\n")
    put!(ch, "//This file is generated. Do not modify it directly.")
    put!(ch, "//This file is for documentation purpose only. Do not include it for compilation.")
    put!(ch, "export function loadTyJuliaCAPI(dllpath: string) {")
    put!(ch, "       return Deno.dlopen(")
    put!(ch, "           dllpath,")
    put!(ch, binding)
    put!(ch, "       );")
    put!(ch, "")
    put!(ch, "}")
    put!(ch, "")
end
