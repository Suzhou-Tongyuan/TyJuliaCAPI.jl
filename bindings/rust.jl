to_rs_type(x::Type{Out{A}}) where A = "*mut " * to_rs_type(A)
to_rs_type(x::Type{Ptr{A}}) where A = "*mut " * to_rs_type(A)
to_rs_type(x::Type{JV}) = "JVSlot"
to_rs_type(x::Type{Int8}) = "i8"
to_rs_type(x::Type{Int16}) = "i16"
to_rs_type(x::Type{Int32}) = "i32"
to_rs_type(x::Type{Float32}) = "f32"
to_rs_type(x::Type{Int64}) = "i64"
to_rs_type(x::Type{Float64}) = "f64"
to_rs_type(x::Type{Bool}) = "u8"
to_rs_type(x::Type{Cvoid}) = "std::ffi::c_void"
to_rs_type(x::Type{TyList{A}}) where A = "CList::<" * to_rs_type(A) * ">"
to_rs_type(x::Type{TyTuple{A, B}}) where {A, B} = "CTuple::<$(to_rs_type(A)), $(to_rs_type(B))>"
to_rs_type(x::Type{JSym}) = "JSymSlot"
to_rs_type(x::Type{UInt32}) = "u32"
to_rs_type(x::Type{UInt64}) = "u64"
to_rs_type(x::Type{ComplexF64}) = "M3Complex::<f64>"
to_rs_type(x::Type{ComplexF32}) = "M3Complex::<f32>"
to_rs_type(x::Type{UInt16}) = "u16"
to_rs_type(x::Type{UInt8}) = "u8"
to_rs_type(x::Type{ErrorCode}) = "ErrorCode"
to_rs_type(x::Type{Compare}) = "u8"

function _gen_rs_api_binding_struct_field(ch, name::Symbol, ns::Signature)
    pars = join([to_rs_type.(ns.pars)...], ", ")
    put!(ch, "pub $name: extern \"C\" fn($pars) -> $(to_rs_type(ns.ret)),")
end

function _gen_rs_api_binding_struct(ch)
    for (name, ns) in apis
        _gen_rs_api_binding_struct_field(ch, name, Signature(ns))
    end
end

_gen_rs_api_binding_struct() = Channel{String}() do ch
    _gen_rs_api_binding_struct(ch)
end

function gen_rs_api_binding_struct(ch)
    put!(ch, "#[repr(C)]")
    put!(ch, "struct JuliaAPI")
    put!(ch, "{")
    for each in _gen_rs_api_binding_struct()
        put!(ch, "    " * each)
    end
    put!(ch, "}")
    put!(ch, "")
    put!(ch, "pub unsafe fn populate_capi(api: &mut JuliaAPI, fn_getter: extern \"C\" fn(*const u8, *mut usize, *mut u8))")
    put!(ch, "{")
    put!(ch, "    let mut fn_ptr: usize = 0;")
    put!(ch, "    let mut status: u8 = 0;")
    for (name, _) in apis
    put!(ch, "    fn_getter(")
    put!(ch, "        b\"$name\\0\".as_ptr(),")
    put!(ch, "        (&mut fn_ptr) as *mut usize,")
    put!(ch, "        (&mut status) as *mut u8,")
    put!(ch, "    );")
    put!(ch, "    if status == 0 { panic!(\"Failed to get $name\"); }")
    put!(ch, "    api.$name = std::mem::transmute(fn_ptr);")
    put!(ch, "    status = 0;")
    end
    put!(ch, "}")
end

gen_rs_api_binding_struct() = Channel{String}() do ch
    gen_rs_api_binding_struct(ch)
end
