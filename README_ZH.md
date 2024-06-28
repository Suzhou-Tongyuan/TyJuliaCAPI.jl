# TyJuliaCAPI.jl


TyJuliaCAPI.jl 为Julia提供一组稳定的C API。

这些API以函数指针形式提供，初始化方法分两种情况：

1. 如果主动调用方是Julia，Julia获取外部语言的C函数，该C函数接受Julia传入的函数指针，使得外部语言能访问这些API。

2. 如果主动调用方是外部语言，由于Julia的官方C API不稳定、无文档，很难使用和（1）相同的方式初始化。这时，可以两方启用一个网络协议，通过网络传递函数指针，使得两方能访问对方的C API（该方式参考了MATLAB互调用）

## 动机

对于TyJuliaCAPI的需求源自一个技术难题：**Julia如何和其他外部语言进行进程内交互**？

TyMLang 主要由 C++/C# 实现，从native代码中调用Julia是一个关键需求。

那么如何从C#调用Julia：这个问题的解决除开走C API，别无它法。

然而，虽然Julia提供了一套C API ([julia.h](https://github.com/JuliaLang/julia/blob/master/src/julia.h))，这些API却有下列问题：

1. 没有文档
2. 需要理解Julia生命周期管理的知识和Julia GC机制
3. API不稳定，每个版本都发生变化

我们因此认定Julia当下的C API质量不足以支撑产品开发和维护。

我们需要一套稳定、通用的Julia C API。

过去，我们从[PythonCall.jl](https://github.com/JuliaPy/PythonCall.jl)中得到了一种有用的技术（以下统称为GC Pooling技术），该技术被PythonCall自身用以提供一套互调用机制，使得PythonCall在稳定性和性能超过了过去的同类项目。我们在调研和实践了该技术后，为Julia实现了一套的通用、稳定、设计优良的C API，即TyJuliaCAPI。

在TyJuliaCAPI中，生命周期管理方式采用了[Python Stable C API](https://docs.python.org/3/c-api/stable.html)（也是目前应用最广、认可度最高的C CAPI设计）的方式：通过C API创建对象，对象自带引用；在无需使用时，调用`JLFreeFromMe`释放外部语言的引用。

```c++
JV myJuliaValue;

if (JLEval(&myJuliaValue, NULL, "1 + 1") != ErrorCode::ok) {
    // 估值失败，错误处理
}

// 使用 myJuliaValue且 无需考虑释放

bool doCast = false; // 不适用严格转换
int64_t myIntValue;

if (JLGetInt32(&myIntValue, myJuliaValue, doCast) != ErrorCode::ok) {
    // 转换失败，错误处理
}

// 使用myIntValie

...

// 使用完毕后，释放
JLFreeFromMe(myJuliaValue);
```

## API list

在API中，以`CORE_API`宏前缀修饰的API是基本核心API；其余API均可用核心API表达，但因为常用性较高，故单独提供。

### 类型

类型需要做ABI级别兼容。

```c++
enum struct ErrorCode: uint8_t {
    ok = 0, error = 1,
};

enum struct Compare: uint8_t {
    SEQ = 0, // === 运算符
    SNE = 1, // !==
    // 以下是常见的6种逻辑运算符
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
/* 对象创建、销毁 */

CORE_API void JLFreeFromMe(JV value);
// ↑ 外部语言使用Finalizer释放Julia对象在外部语言运行时的引用，但不代表在Julia运行时的引用被释放
// ↑ value为空值不引发错误

/* 抛错时是否输出Julia的堆栈信息，默认为不输出 */
CORE_API void JLError_EnableBackTraceMsg(bool hasStackTraceMsg);

/* 反射 */
CORE_API ErrorCode JLEval(JV* out, /* nullable */ JV module, List<char> code);
CORE_API ErrorCode JLError_FetchMsgSize(int64_t* size);
CORE_API ErrorCode JLError_FetchMsgStr(JSym* outExcName, List<char> msgBuffer);

/* 对象模型 */
/* func(args...; kwargs...) -> out */
CORE_API ErrorCode JLCall(JV* out, JV func, List<JV> args, List<Tuple<JSym, JV>> kwargs);
/* func.(args...; kwargs...) -> out */
CORE_API ErrorCode JLDotCall(JV* out, JV func, List<JV> args, List<Tuple<JSym, JV>> kwargs);

ErrorCode JLCompare(bool* out, Compare cmp, JV a, JV b);
```

全量API列表见 [`include/tyjuliacapi.hpp`](./include/tyjuliacapi-docs.hpp)

## 外部语言binding

目前我们为TyMLang实现了C\#语言的binding生成器，见`bindings/csharp.jl`。

### 为C\#生成TyJuliaCAPI的binding：

```bash
> CS_BINDING=/path/to/generated_csharp_file.cs bash build.sh
```

### 生成C声明

```
> CPP_BINDING_DIR=/dir/to/generated_hpp_files bash build.sh
```
