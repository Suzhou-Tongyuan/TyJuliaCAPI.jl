## Instructions

1. C++ library source code: `library.cpp`
2. Julia loading code: `test.jl`

## Example

```
bash> g++ -fPIC -shared library.cpp -I../../include -o library.dll
bash> julia
julia> using TyJuliaCAPI
julia> include("test.jl")
The rank of the computed array is: 1
```
