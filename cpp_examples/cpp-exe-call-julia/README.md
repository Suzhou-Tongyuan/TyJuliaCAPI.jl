# Calling Julia from an Executable Built in C++

## Requirements

C++ compilers such as `g++` and `clang++`

## Build

Note: You can obtain the Julia binary folder path using `unsafe_string(Base.JLOptions().julia_bindir)`.

1. Navigate to the current folder and execute the following code:

    ```bash
    # You can also use clang++ instead of g++
    g++ -std=c++11 main.cpp \
         # Julia header file path; below is an example for a Julia 1.7 environment on Windows
         -I"C:\Users\Public\TongYuan\julia-1.7.3\include\julia" \
         # TyJuliaCAPI library folder, relative path used here
         -I../../include \
         # Output file name
         -o main.exe \
         # Julia library folder path; below is an example for a Julia 1.7 environment on Windows
         -L"C:\Users\Public\TongYuan\julia-1.7.3\lib" \
         # Required flags
         -ljulia -lopenlibm

    # Additionally, when copying and pasting, make sure to remove the comments as follows:
    g++ -std=c++11 main.cpp -I"C:\Users\Public\TongYuan\julia-1.7.3\include\julia" -I../../include -o main.exe -L"C:\Users\Public\TongYuan\julia-1.7.3\lib" -ljulia -lopenlibm
    ```

2. Ensure that the `TyJuliaCAPI.jl` package is installed in your global Julia environment.

3. Set the environment variable:

   - Windows: Add the Julia binary folder to the PATH.

   - Linux: Add the Julia binary folder to the LD_LIBRARY_PATH.

4. Run `main.exe`, and you will see the output.

## Preview

In this demo, we have implemented a simple REPL that allows you to enter Julia code in the command line, execute it, and print the results. If an error occurs, it will be printed as well.

```
julia-demo> 1
result =>
1

julia-demo> 1 .+ [1, 2]
result =>
Vector{Int64}
 1
 3
```