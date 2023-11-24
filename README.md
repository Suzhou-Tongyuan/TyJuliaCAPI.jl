# TyJuliaCAPI.jl

[![Build Status](https://github.com/Suzhou-Tongyuan/TyJuliaCAPI.jl/actions/workflows/Test.yml/badge.svg?branch=main
)](https://github.com/Suzhou-Tongyuan/TyJuliaCAPI.jl/actions/workflows/Test.yml?query=branch%3Amain) [![中文文档](https://img.shields.io/badge/%E4%B8%AD%E6%96%87-%E6%96%87%E6%A1%A3-blue.svg)](README_ZH.md)

TyJuliaCAPI.jl provides a stable C API for Julia.

These APIs are provided in the form of function pointers, and there are two initialization methods:

1. If the caller is Julia, Julia obtains C functions from the external language. These C functions accept function pointers passed by Julia, allowing the external language to access these APIs.

2. If the caller is an external language, due to the instability and lack of documentation of Julia's official C API, it is difficult to initialize in the same way as in (1). In this case, we can enable a network protocol to transmit function pointers over the network, allowing both two side to access each other's C API (this approach is inspired by MATLAB's interoperability).

## Motivation

The need for TyJuliaCAPI arises from a technical challenge: **How can Julia interact with other external languages within the same process**?

We have serval projects implemented in C++/C#, and calling Julia from native code is a crucial requirement.

So, how to call Julia from C#: The only solution to this problem is to use the C API.

However, although Julia provides a C API ([julia.h](https://github.com/JuliaLang/julia/blob/master/src/julia.h)), these APIs have the following issues:

1. Lack of documentation.
2. Requires an understanding of Julia's lifecycle management and garbage collection mechanism.
3. The API is unstable and changes with every version.

We, therefore, believe that the current quality of Julia's C API is insufficient to support product development and maintenance.

And we need a stable and generic Julia C API.

In the past, we have learned a useful technique from [PythonCall.jl](https://github.com/JuliaPy/PythonCall.jl) (referred to as GC Pooling), which PythonCall itself used to provide a set of interoperation mechanisms, surpassing similar projects in terms of stability and performance. Following this technique, we have implemented a stable and well-designed C API for Julia, which we call TyJuliaCAPI.

In TyJuliaCAPI, the lifecycle management is adopted in a manner similar to the [Python Stable C API](https://docs.python.org/3/c-api/stable.html) (the most widely applied and highly regarded C API design): objects are created via the C API with inherent references, and when they are no longer needed, external language references are released by using `JLFreeFromMe`.

```c++
JV myJuliaValue;

if (JLEval(&myJuliaValue, NULL, "1 + 1") != ErrorCode::ok) {
    // Evaluation failed, handle the error
}

// Use myJuliaValue without worrying about releasing it

bool doCast = false; // Not using casting
int64_t myIntValue;

if (JLGetInt32(&myIntValue, myJuliaValue, doCast) != ErrorCode::ok) {
    // Conversion failed, handle the error
}

// Use myIntValue

...

// Release when done using
JLFreeFromMe(myJuliaValue);
```

## API list

APIs prefixed with the `CORE_API` macro are fundamental core APIs, while the rest of the APIs can be expressed using the core APIs. However, they are provided separately due to their high level of common usage.

### Types

Types need to be ABI-level compatible.

```c++
enum struct ErrorCode: uint8_t {
    ok = 0, error = 1,
};

enum struct Compare: uint8_t {
    SEQ = 0, // === operator
    SNE = 1, // !==
    // The following are the six common logical operators
    EQ = 2, NE = 3, LT = 4, LE = 5, GT = 6, GE = 7
};

struct complex_t {
    double re;
    double im;
};

typedef int64_t JV;
typedef int64_t JSym;

template<typename T>
struct List {
    int64_t len;
    T* data;
};

template<typename L, typename R>
struct Tuple {
    L l;
    R r;
};
```

### API

```c++
/* Object Creation and Destruction */

CORE_API void JLFreeFromMe(JV value);
// ↑ Used by the external language to release the reference to a Julia object in the external language runtime, but does not imply the release of the reference in the Julia runtime.
// ↑ A null value for `value` does not trigger an error.

/* Enable or Disable Julia Stack Trace Information when Throwing Errors (default is disabled) */
CORE_API void JLError_EnableBackTraceMsg(bool hasStackTraceMsg);

/* Reflection */
CORE_API ErrorCode JLEval(JV* out, /* nullable */ JV module, List<char> code);
CORE_API ErrorCode JLError_FetchMsgSize(int64_t* size);
CORE_API ErrorCode JLError_FetchMsgStr(JSym* outExcName, List<char> msgBuffer);

/* Object Model */
/* func(args...; kwargs...) -> out */
CORE_API ErrorCode JLCall(JV* out, JV func, List<JV> args, List<Tuple<JSym, JV>> kwargs);
/* func.(args...; kwargs...) -> out */
CORE_API ErrorCode JLDotCall(JV* out, JV func, List<JV> args, List<Tuple<JSym, JV>> kwargs);

ErrorCode JLCompare(bool* out, Compare cmp, JV a, JV b);
```

The complete API list can be found in [`include/tyjuliacapi.hpp`](include/tyjuliacapi-docs.hpp).


## External Language Binding

Currently, we have implemented a C# language binding generator, which can be found in `bindings/csharp.jl`.

### To generate bindings for TyJuliaCAPI for C#:

```bash
> CS_BINDING=/path/to/generated_csharp_file.cs bash build.sh
```

### To generate C declarations:

```bash
> CPP_BINDING_DIR=/dir/to/generated_hpp_files bash build.sh
```

These commands allow you to generate the necessary bindings for TyJuliaCAPI in the specified language, making it accessible and usable in your project.
