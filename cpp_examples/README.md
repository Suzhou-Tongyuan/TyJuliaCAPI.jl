# C++ Calling Julia

TyJuliaCAPI is the underlying technology used by the TongYuan M Language to call Julia, and it also supports calling Julia from C++.

Unlike `julia.h`, TyJuliaCAPI provides a **long-term stable** C API. The data structures and function signatures involved in this API will not change with Julia version upgrades.

## Features Overview

1. Cross-thread calls to the Julia C API are not supported (julia.h does not support this at the current stage either).

2. When writing a Julia library in C/C++, there is no need to include `julia.h`. You only need to include two header files from TyJuliaCAPI, and it supports static linking.

3. The lifecycle management of Julia objects follows the design of the CPython Stable C API, which is the industry-standard approach for managing object lifecycles when calling C code from external languages.

4. The API is minimal in number but comprehensive in functionality, making it suitable for further development.

## Usage and Examples

C++ calling Julia serves two main purposes, each of which is demonstrated with a corresponding demo:

1. Building an executable and calling Julia: Refer to [cpp-exe-call-julia](./cpp-exe-call-julia).

2. Using C++ to write a Julia library that calls Julia and is ultimately called by Julia: Refer to [cpp-write-jl-lib](./cpp-write-jl-lib).
