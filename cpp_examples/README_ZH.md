# C++调用Julia

TyJuliaCAPI是同元M语言调用Julia的底层技术，它也支持C++调用Julia。

与`julia.h`不同，TyJuliaCAPI提供一套**长期稳定**的C API，其中涉及的数据结构和函数签名不会随着Julia版本升级而发生改变。

## 特性概览

1. 不支持跨线程调用Julia C API（现阶段julia.h也不支持）

2. 使用C/C++编写Julia库时，无需包含`julia.h`，只需包含TyJuliaCAPI的两个头文件，且支持静态链接。

3. Julia对象的生命周期管理参考CPython Stable C API设计，是业界主流的外部语言调用C语言的对象生命周期管理方式。

4. API数量少，但功能完备，适合二次开发。

## 使用和案例

C++调用Julia有以下两种目的，分别提供了一个demo进行演示：

1. 构建可执行文件并调用Julia：查看[cpp-exe-call-julia](./cpp-exe-call-julia)

2. 使用C++编写Julia库，其中调用到Julia，并最终为Julia调用：查看[cpp-write-jl-lib](./cpp-write-jl-lib)
