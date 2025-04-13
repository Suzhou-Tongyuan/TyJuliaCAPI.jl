@testset "Eval" begin
    s = "123"
    x = TyList(s)
    out = [JV()]
    GC.@preserve s begin
        @test JLEval(pointer(out), JV(), x) == OK
        @test JV_LOAD(out[1]) == 123
        JV_DEALLOC(out[1])
        v = JV_ALLOC(StridedArray)
        @test v.ID == 1
        JV_DEALLOC(v)
    end

    JLError_EnableBackTraceMsg(true)
    s = "div(1, 0)"
    x = TyList(s)
    out = [JV()]
    GC.@preserve s begin
        @test JLEval(pointer(out), JV(), x) == ERROR
        errSizeOut = Int64[0]
        @test FetchJLErrorSize(pointer(errSizeOut)) == OK
        errMsgVec = Vector{UInt8}(undef, errSizeOut[1])

        refSym = [JSym()]
        @test FetchJLError(
            pointer(refSym), TyList(length(errMsgVec), pointer(errMsgVec))
        ) == OK
        @test JSym_LOAD(refSym[1]) == :DivideError
        @test countlines(IOBuffer(errMsgVec)) > 3
    end

    JLError_EnableBackTraceMsg(false)
    s = "try"
    x = TyList(s)
    out = [JV()]
    GC.@preserve s begin
        @test JLEval(pointer(out), JV(), x) == ERROR
        errSizeOut = Int64[0]
        @test FetchJLErrorSize(pointer(errSizeOut)) == OK
        errMsgVec = Vector{UInt8}(undef, errSizeOut[1])

        refSym = [JSym()]
        @test FetchJLError(
            pointer(refSym), TyList(length(errMsgVec), pointer(errMsgVec))
        ) == OK
        if VERSION >= v"1.10.0"
            @test JSym_LOAD(refSym[1]) == :ParseError
        else
            @test JSym_LOAD(refSym[1]) == :ErrorException
            @test String(errMsgVec) == "syntax: incomplete: premature end of input"
        end
    end

    s = """
        if true
            123
        else
            234
        end
        345
        """
    x = TyList(s)
    out = [JV()]
    GC.@preserve s begin
        @test JLEval(pointer(out), JV(), x) == OK
        @test JV_LOAD(out[1]) == 345
        JV_DEALLOC(out[1])
    end
end

@testset "JLCall" begin
    # CORE_API ErrorCode JLCall(JV* out, JV func, List<JV> args, List<Tuple<Sym, JV>> kwargs);
    # CORE_API ErrorCode JLDotCall(JV* out, JV func, List<JV> args, List<Tuple<Sym, JV>> kwargs);

    fProxy = JV_ALLOC(+)
    arg1Proxy = JV_ALLOC(1.0)
    arg2Proxy = JV_ALLOC(2.3)
    out = [JV()]
    args = [arg1Proxy, arg2Proxy]
    kwargs = Ptr{TyTuple{JSym,JV}}(C_NULL)
    @test JLCall(pointer(out), fProxy, TyList(2, pointer(args)), TyList(0, kwargs)) == OK
    @test JV_LOAD(out[1]) == 3.3
    JV_DEALLOC(out[1])

    function myfunc(a; b)
        return a * b
    end

    fProxy = JV_ALLOC(myfunc)
    arg1Proxy = JV_ALLOC("AAA")
    arg2Proxy = JV_ALLOC("BCB")
    out = [JV()]
    args = [arg1Proxy]
    kwargs = [TyTuple(JSym(:b), arg2Proxy)]
    @test JLCall(
        pointer(out), fProxy, TyList(1, pointer(args)), TyList(1, pointer(kwargs))
    ) == OK
    @test JV_LOAD(out[1]) == "AAABCB"
    JV_DEALLOC(out[1])

    fProxy = JV_ALLOC(myfunc)
    arg1Proxy = JV_ALLOC([1, 2, 3])
    arg2Proxy = JV_ALLOC([5, 2, 8])
    out = [JV()]
    args = [arg1Proxy]
    kwargs = [TyTuple(JSym(:b), arg2Proxy)]
    @test JLDotCall(
        pointer(out), fProxy, TyList(1, pointer(args)), TyList(1, pointer(kwargs))
    ) == OK
    @test JV_LOAD(out[1]) == myfunc.([1, 2, 3]; b=[5, 2, 8])
    JV_DEALLOC(out[1])

    function myfunc3(a, b, c)
        return a * b * c
    end
    fProxy = JV_ALLOC(myfunc3)
    arg1Proxy = JV_ALLOC("AAA")
    arg2Proxy = JV_ALLOC("BCB")
    arg3Proxy = JV_ALLOC("CCC")
    out = [JV()]
    args = [arg1Proxy, arg2Proxy, arg3Proxy]
    kwargs = Ptr{TyTuple{JSym,JV}}(C_NULL)
    @test JLCall(pointer(out), fProxy, TyList(3, pointer(args)), TyList(0, kwargs)) == OK
    @test JV_LOAD(out[1]) == "AAABCBCCC"
    JV_DEALLOC(out[1])
    JV_DEALLOC(fProxy)
    JV_DEALLOC(arg1Proxy)
    JV_DEALLOC(arg2Proxy)
    JV_DEALLOC(arg3Proxy)
end

mutable struct MyVal
    x::Any
end

@testset "JLSymToJV + JLTypeOf" begin
    @test :a == JV_LOAD(JSymToJV(JSym(:a)))

    @test JV_LOAD(JLTypeOf(JV_ALLOC(MyVal(1)))) == MyVal
end

@testset "JLCompare" begin
    a = JV_ALLOC(1)
    b = JV_ALLOC(1.0)
    c = JV_ALLOC("1.0")
    d = JV_ALLOC("1.0")
    e = JV_ALLOC(5)
    f = JV_ALLOC(10)

    out = Bool[false]

    @test JLCompare(pointer(out), TyJuliaCAPI.SEQ, c, d) == OK
    @test out[1] === true

    out[1] = false
    @test JLCompare(pointer(out), TyJuliaCAPI.SNE, a, b) == OK
    @test out[1] === true

    out[1] = true
    @test JLCompare(pointer(out), TyJuliaCAPI.SEQ, a, b) == OK
    @test out[1] === false

    out[1] = false
    @test JLCompare(pointer(out), TyJuliaCAPI.EQ, a, b) == OK
    @test out[1] === true

    out[1] = false
    @test JLCompare(pointer(out), TyJuliaCAPI.LT, a, e) == OK
    @test out[1] === true

    out[1] = false
    @test JLCompare(pointer(out), TyJuliaCAPI.LE, a, e) == OK
    @test out[1] === true

    out[1] = false
    @test JLCompare(pointer(out), TyJuliaCAPI.GT, f, e) == OK
    @test out[1] === true

    out[1] = false
    @test JLCompare(pointer(out), TyJuliaCAPI.GE, f, e) == OK
    @test out[1] === true

    out[1] = false
    @test JLCompare(pointer(out), TyJuliaCAPI.GE, f, f) == OK
    @test out[1] === true

    out[1] = true
    @test JLCompare(pointer(out), TyJuliaCAPI.GT, f, f) == OK
    @test out[1] === false

    JV_DEALLOC(a)
    JV_DEALLOC(b)
    JV_DEALLOC(c)
    JV_DEALLOC(d)
    JV_DEALLOC(e)
    JV_DEALLOC(f)
end

@testset "Property" begin
    # ErrorCode JLGetProperty(JV* out, JV self, JSym property); // 等价于getproperty
    # ErrorCode JLSetProperty(JV self, JSym property, JV value); // 等价于setproperty!
    # ErrorCode JLHasProperty(bool* out, JV self, JSym property); //

    self = MyVal(:asdasadas)
    prop = :x

    selfProxy = JV_ALLOC(self)
    propCache = JSym(prop)

    out = [JV()]
    @test JLGetProperty(pointer(out), selfProxy, propCache) == OK
    @test JV_LOAD(out[1]) == :asdasadas

    @test JLSetProperty(selfProxy, propCache, JV_ALLOC(123)) == OK
    @test self.x == 123

    out = Bool[false]
    @test JLHasProperty(pointer(out), selfProxy, propCache) == OK
    @test out[1] === true

    out = Bool[true]
    @test JLHasProperty(pointer(out), selfProxy, JSym(:y)) == OK
    @test out[1] === false
end

@testset "Index" begin
    # ErrorCode JLGetIndex(JV* out, JV self, List<JV> index); // 等价于getindex
    # ErrorCode JLSetIndex(JV self, List<JV> index, JV value); // 等价于setindex!

    self = [1, 2, 3, 4]
    index = JV_ALLOC(2)

    selfProxy = JV_ALLOC(self)
    out = [JV()]
    indices = [index]
    @test JLGetIndex(pointer(out), selfProxy, TyList(1, pointer(indices))) == OK
    @test JV_LOAD(out[1]) == self[2]

    newValue = JV_ALLOC(100)
    @test JLSetIndex(selfProxy, TyList(1, pointer(indices)), newValue) == OK
    @test self[2] == 100

    JV_DEALLOC(out[1])
    JV_DEALLOC(selfProxy)
    JV_DEALLOC(index)
    JV_DEALLOC(newValue)

    # test for multiple indices
    self = [[1 2 3]; [4 5 6]]
    row = JV_ALLOC(1)
    col = JV_ALLOC(2)

    selfProxy = JV_ALLOC(self)
    out = [JV()]
    indices = [row, col]
    @test JLGetIndex(pointer(out), selfProxy, TyList(2, pointer(indices))) == OK
    @test JV_LOAD(out[1]) == self[1, 2]

    newValue = JV_ALLOC(200)
    @test JLSetIndex(selfProxy, TyList(2, pointer(indices)), newValue) == OK
    @test self[1, 2] == 200

    JV_DEALLOC(out[1])
    JV_DEALLOC(selfProxy)
    JV_DEALLOC(row)
    JV_DEALLOC(col)
    JV_DEALLOC(newValue)

    # test for indexing with character
    self = ["hello", "world"]
    index = JV_ALLOC(2)

    selfProxy = JV_ALLOC(self)
    out = [JV()]
    indices = [index]
    @test JLGetIndex(pointer(out), selfProxy, TyList(1, pointer(indices))) == OK
    @test JV_LOAD(out[1]) == self[2]

    newValue = JV_ALLOC("goodbye")
    @test JLSetIndex(selfProxy, TyList(1, pointer(indices)), newValue) == OK
    @test self[2] == "goodbye"

    JV_DEALLOC(out[1])
    JV_DEALLOC(selfProxy)
    JV_DEALLOC(index)
    JV_DEALLOC(newValue)
end

@testset "Get" begin
    asym = JV_ALLOC(:x)
    abool = JV_ALLOC(true)
    auint8 = JV_ALLOC(UInt8(2))
    auint16 = JV_ALLOC(UInt16(2))
    auint32 = JV_ALLOC(UInt32(3))
    auint64 = JV_ALLOC(UInt64(4))
    aint8 = JV_ALLOC(Int8(5))
    aint16 = JV_ALLOC(Int16(5))
    aint32 = JV_ALLOC(Int32(5))
    aint64 = JV_ALLOC(Int64(6))
    afloat32 = JV_ALLOC(Float32(1))
    afloat64 = JV_ALLOC(Float64(2))
    acomplexf64 = JV_ALLOC(ComplexF64(2.0, 3.0))
    acomplexf32 = JV_ALLOC(ComplexF32(2.0, 3.0))

    astr = "Hello"
    astr′ = JV_ALLOC(astr)

    out = [JSym()]

    @test JLGetSymbol(pointer(out), asym, true) == OK
    @test JSym_LOAD(out[1]) === :x
    @test JLGetSymbol(pointer(out), asym, false) == OK
    @test JSym_LOAD(out[1]) === :x

    out = [false]
    @test JLGetBool(pointer(out), abool, false) == OK
    @test out[1] === true
    @test JLGetBool(pointer(out), afloat32, true) == OK
    @test out[1] === true

    out = UInt8[0]
    @test JLGetUInt8(pointer(out), auint8, false) == OK
    @test out[1] === UInt8(2)
    @test JLGetUInt8(pointer(out), auint32, true) == OK
    @test out[1] === UInt8(3)

    out = UInt16[0]
    @test JLGetUInt16(pointer(out), auint16, false) == OK
    @test out[1] === UInt16(2)
    @test JLGetUInt16(pointer(out), auint32, true) == OK
    @test out[1] === UInt16(3)

    out = UInt32[0]
    @test JLGetUInt32(pointer(out), auint32, false) == OK
    @test out[1] === UInt32(3)
    @test JLGetUInt32(pointer(out), aint64, true) == OK
    @test out[1] === UInt32(6)

    out = UInt64[0]
    @test JLGetUInt64(pointer(out), auint64, false) == OK
    @test out[1] === UInt64(4)
    @test JLGetUInt64(pointer(out), afloat64, true) == OK
    @test out[1] === UInt64(2)

    out = Int8[0]
    @test JLGetInt8(pointer(out), aint8, false) == OK
    @test out[1] === Int8(5)
    @test JLGetInt8(pointer(out), afloat32, true) == OK
    @test out[1] === Int8(1)

    out = Int16[0]
    @test JLGetInt16(pointer(out), aint16, false) == OK
    @test out[1] === Int16(5)
    @test JLGetInt16(pointer(out), afloat32, true) == OK
    @test out[1] === Int16(1)

    out = Int32[0]
    @test JLGetInt32(pointer(out), aint32, false) == OK
    @test out[1] === Int32(5)
    @test JLGetInt32(pointer(out), afloat32, true) == OK
    @test out[1] === Int32(1)

    out = Int64[0]
    @test JLGetInt64(pointer(out), aint64, false) == OK
    @test out[1] === Int64(6)
    @test JLGetInt64(pointer(out), auint64, true) == OK
    @test out[1] === Int64(4)

    out = Float32[0]
    @test JLGetSingle(pointer(out), afloat32, false) == OK
    @test out[1] === Float32(1)
    @test JLGetSingle(pointer(out), aint32, true) == OK
    @test out[1] === Float32(5)

    out = Float64[0]
    @test JLGetDouble(pointer(out), afloat64, false) == OK
    @test out[1] === Float64(2)
    @test JLGetDouble(pointer(out), auint64, true) == OK
    @test out[1] === Float64(4)

    out = ComplexF64[0]
    @test JLGetComplexF64(pointer(out), acomplexf64, false) == OK
    @test out[1] === ComplexF64(2, 3)

    out = ComplexF32[0]
    @test JLGetComplexF32(pointer(out), acomplexf32, false) == OK
    @test out[1] === ComplexF32(2, 3)

    strbuff = Vector{UInt8}(undef, ncodeunits(astr))

    buf = TyList(length(strbuff), pointer(strbuff))
    GC.@preserve strbuff begin
        @test JLGetUTF8String(buf, astr′) == OK
        @test unsafe_string(buf) === "Hello"
    end
end

@testset "share data" begin
    rawvec = [5, 2, 7, 4]
    x = JV_ALLOC(rawvec)
    data = Ptr{UInt8}[C_NULL]
    lenRef = Int64[0]
    GC.@preserve data lenRef begin
        @test OK == JLGetArrayPointer(pointer(data), pointer(lenRef), x)
        @test lenRef[1] == 4
        @test data[1] == pointer(rawvec)
        ptr = reinterpret(Ptr{Int}, data[1])
        for i in 1:length(rawvec)
            @test unsafe_load(ptr, i) == rawvec[i]
        end
    end
end

import Base: Libc

function _tmalloc(::Type{T}) where {T}
    return reinterpret(Ptr{T}, Libc.malloc(sizeof(T)))
end

@testset "exportc" begin
    for each in TyJuliaCAPI.APINames
        name = string(each)
        ref_fptr = Ptr{Cvoid}[C_NULL]
        ref_value = Bool[0]
        GC.@preserve name begin
            TyJuliaCAPI.get_capi(Cstring(pointer(name)), pointer(ref_fptr), pointer(ref_value))
        end
        @test ref_value[1] == true
    end
end

@testset "to julia" begin
    out = [JV()]
    x = "Hello"
    GC.@preserve x out begin
        @test ToJLString(pointer(out), TyList(ncodeunits(x), pointer(x))) == OK
    end
    @test JV_LOAD(out[1]) == x

    GC.@preserve out begin
        @test ToJLInt8(pointer(out), Int8(1)) == OK
    end
    @test JV_LOAD(out[1]) === Int8(1)

    GC.@preserve out begin
        @test ToJLInt16(pointer(out), Int16(1)) == OK
    end
    @test JV_LOAD(out[1]) === Int16(1)

    GC.@preserve out begin
        @test ToJLInt32(pointer(out), Int32(1)) == OK
    end
    @test JV_LOAD(out[1]) === Int32(1)

    GC.@preserve out begin
        @test ToJLInt64(pointer(out), Int64(1)) == OK
    end
    @test JV_LOAD(out[1]) === Int64(1)

    GC.@preserve out begin
        @test ToJLUInt64(pointer(out), UInt64(1)) == OK
    end
    @test JV_LOAD(out[1]) === UInt64(1)

    GC.@preserve out begin
        @test ToJLUInt32(pointer(out), UInt32(1)) == OK
    end
    @test JV_LOAD(out[1]) === UInt32(1)

    GC.@preserve out begin
        @test ToJLUInt16(pointer(out), UInt16(1)) == OK
    end
    @test JV_LOAD(out[1]) === UInt16(1)

    GC.@preserve out begin
        @test ToJLUInt8(pointer(out), UInt8(1)) == OK
    end
    @test JV_LOAD(out[1]) === UInt8(1)

    GC.@preserve out begin
        @test ToJLFloat64(pointer(out), Cdouble(1)) == OK
    end
    @test JV_LOAD(out[1]) === Cdouble(1)

    GC.@preserve out begin
        @test ToJLFloat32(pointer(out), Float32(1)) == OK
    end
    @test JV_LOAD(out[1]) === Float32(1)


    GC.@preserve out begin
        @test ToJLComplexF64(pointer(out), ComplexF64(1)) == OK
    end
    @test JV_LOAD(out[1]) === ComplexF64(1)

    GC.@preserve out begin
        @test ToJLComplexF32(pointer(out), ComplexF32(1)) == OK
    end
    @test JV_LOAD(out[1]) === ComplexF32(1)

    out = [JSym()]
    s = "a12345"

    GC.@preserve s begin
        buf = TyList(ncodeunits(s), pointer(s))
        @test JSymFromString(pointer(out), buf) == OK
        @test JSym_LOAD(out[1]) === :a12345
    end
end

@testset "array" begin
    a = JV_ALLOC(rand(6, 4, 5))
    out = Int64[0]
    @test OK == JLArray_Size(pointer(out), a, 0)
    @test out[1] == 6
    @test OK == JLArray_Rank(pointer(out), a)
    @test out[1] == 3
end


@testset "isa & typeof with type slot" begin
    slot_int = TyJuliaCAPI.JTypeToIdent(Int)
    jv_int = JV_ALLOC(1)
    @test JLTypeOfAsTypeSlot(jv_int) == slot_int
    @test JLIsInstanceWithTypeSlot(jv_int, slot_int) == true
    @test JLIsInstanceWithTypeSlot(jv_int, TyJuliaCAPI.JTypeToIdent(Float64)) == false
    @test JLIsInstanceWithTypeSlot(jv_int, TyJuliaCAPI.JTypeToIdent(Any)) == true
    @test JLIsInstanceWithTypeSlot(jv_int, TyJuliaCAPI.JTypeToIdent(Number)) == true

    JV_DEALLOC(jv_int)
end

@testset "compute common tag" begin
    j_int32 = JV_ALLOC(Int32(1))
    @test TyJuliaCAPI.JLCommonTag(j_int32) == TyJuliaCAPI.Tag_I32
    JV_DEALLOC(j_int32)

    j_int64 = JV_ALLOC(Int64(1))
    @test TyJuliaCAPI.JLCommonTag(j_int64) == TyJuliaCAPI.Tag_I64
    JV_DEALLOC(j_int64)

    j_uint32 = JV_ALLOC(UInt32(1))
    @test TyJuliaCAPI.JLCommonTag(j_uint32) == TyJuliaCAPI.Tag_U32
    JV_DEALLOC(j_uint32)

    j_uint64 = JV_ALLOC(UInt64(1))
    @test TyJuliaCAPI.JLCommonTag(j_uint64) == TyJuliaCAPI.Tag_U64
    JV_DEALLOC(j_uint64)

    j_float32 = JV_ALLOC(Float32(1))
    @test TyJuliaCAPI.JLCommonTag(j_float32) == TyJuliaCAPI.Tag_F32
    JV_DEALLOC(j_float32)

    j_float64 = JV_ALLOC(Float64(1))
    @test TyJuliaCAPI.JLCommonTag(j_float64) == TyJuliaCAPI.Tag_F64
    JV_DEALLOC(j_float64)

    j_bool = JV_ALLOC(true)
    @test TyJuliaCAPI.JLCommonTag(j_bool) == TyJuliaCAPI.Tag_B8
    JV_DEALLOC(j_bool)

    j_string = JV_ALLOC("hello")
    @test TyJuliaCAPI.JLCommonTag(j_string) == TyJuliaCAPI.Tag_String
    JV_DEALLOC(j_string)

    j_simple_vector = JV_ALLOC(Core.svec(1, 2, 3))
    @test TyJuliaCAPI.JLCommonTag(j_simple_vector) == TyJuliaCAPI.Tag_SimpleVector
    JV_DEALLOC(j_simple_vector)

    j_vector = JV_ALLOC([1, 2, 3])
    @test TyJuliaCAPI.JLCommonTag(j_vector) == TyJuliaCAPI.Tag_Vector
    JV_DEALLOC(j_vector)

    j_dict = JV_ALLOC(Dict())
    @test TyJuliaCAPI.JLCommonTag(j_dict) == TyJuliaCAPI.Tag_Unknown
    JV_DEALLOC(j_dict)
end

@testset "shared object" begin
    obj = Dict()
    j_dict = JV_ALLOC(obj)
    out = [JV()]
    GC.@preserve out begin
        @test TyJuliaCAPI.JLNewOwner(pointer(out), j_dict) == OK
    end
    @test JV_LOAD(out[1]) === obj
    @test out[1] != j_dict
    JV_DEALLOC(out[1])
    JV_DEALLOC(j_dict)
end