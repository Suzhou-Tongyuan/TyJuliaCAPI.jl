# 从C++构建的可执行文件中调用Julia

## 软件需求

`g++`, `clang++`等C++编译器

## 构建方式

注：通过`unsafe_string(Base.JLOptions().julia_bindir)`可以获取Julia二进制文件夹路径

1. 进入当前文件夹，执行以下代码：

    ```bash
    # 或使用 clang++ ..
    g++ -std=c++11 main.cpp \
         # Julia头文件路径，下面是Windows上同元Julia 1.7环境的示例
         -I"C:\Users\Public\TongYuan\julia-1.7.3\include\julia" \
         # TyJuliaCAPI库文件夹，此处是相对路径
         -I../../include \
         # 输出文件名
         -o main.exe \
         # Julia库文件夹路径，下面是Windows上同元Julia 1.7环境的示例
         -L"C:\Users\Public\TongYuan\julia-1.7.3\lib" \
         # 必选项
         -ljulia -lopenlibm

    # 另外，粘贴复制时请注意消除上面的注释，如：
    g++ -std=c++11 main.cpp -I"C:\Users\Public\TongYuan\julia-1.7.3\include\julia" -I../../include -o main.exe -L"C:\Users\Public\TongYuan\julia-1.7.3\lib" -ljulia -lopenlibm
    ```

2. 确保全局Julia环境中安装了`TyJuliaCAPI.jl`

3. 设置环境变量：

   - Windows：将Julia二进制文件夹添加到PATH中

   - Linux：将Julia二进制文件夹添加到LD_LIBRARY_PATH中

4. 运行`main.exe`，即可看到输出

## 效果预览

本demo我们实现了一个简单的REPL，可以在命令行中输入Julia代码，然后执行并打印结果；如发生错误则打印错误。

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