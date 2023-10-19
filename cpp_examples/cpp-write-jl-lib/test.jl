using Libdl
using TyJuliaCAPI
dl = Libdl.dlopen("./library.dll")

library_init = Libdl.dlsym(dl, :library_init)
capi_getter = TyJuliaCAPI.get_capi_getter()

ok = @ccall $library_init(capi_getter::Ptr{Cvoid})::Bool
if !ok
    error("Failed to load library")
end

evaluateAndGetRank = Libdl.dlsym(dl, :evaluateAndGetRank)
@ccall $evaluateAndGetRank("[1] .+ 2"::Cstring)::Cint
