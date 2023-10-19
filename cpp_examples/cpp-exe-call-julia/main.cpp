/* Generate an executable, no dynamic libraries required */
#define DLLEXPORT

#include "julia.h"
#include "tyjuliacapi.hpp"
#include <iostream>
#include <string>

JULIA_DEFINE_FAST_TLS; // Only define this once, in an executable (not in a shared library) if you want fast code.

/**
    Used to initialize TyJuliaCAPI from C++
*/
void init_tyjuliacapi()
{
    jl_value_t *ret = jl_eval_string("using TyJuliaCAPI;UInt64(TyJuliaCAPI.get_capi_getter())");
    if (!ret)
    {
        printf("jl_eval_string failed: TyJuliaCAPI is invalid\n");
        exit(1);
    }

    JL_GC_PUSH1(&ret);
    if (!jl_is_uint64(ret))
    {
        printf("jl_eval_string failed: TyJuliaCAPI is invalid\n");
        exit(1);
    }
    uint64_t capi_getter = jl_unbox_uint64(ret);
    JL_GC_POP();

    if (library_init(reinterpret_cast<_get_capi_t>(capi_getter)) == 0)
    {
        printf("library_init failed: TyJuliaCAPI is invalid\n");
        exit(1);
    }
}

int main()
{
    /* Fixed initialization process for all executables */
    jl_init();
    init_tyjuliacapi();

    /* Declare variables */
    JV res;
    JV display;
    JSym errorSym;

    // Enable Julia to throw errors and return stack traces
    USE_STACKTRACE_MSG_LOCALLY;
    /*
        Principle of enabling stack traces:
        1. Set the value of a status variable to JLError_HasBackTraceMsg();
        2. Call JLError_EnableBackTraceMsg(true);
        3. At the end of the scope, call JLError_EnableBackTraceMsg(original status variable);
    */

    /* Allocate space for error information; for simplicity, allocate 2048 bytes of space */
    // P.S: You can use FetchJLErrorSize to get the length of error information and allocate appropriate space
    std::string consoleInput;

    const char *_displayCode = "display";
    char *displayCode = const_cast<char*>(_displayCode);

    /* Evaluate the 'display' function in the Main module and store it in the 'display' variable */

    if (ErrorCode::ok != JLEval(&display, NULL, SList_adapt(reinterpret_cast<uint8_t *>(displayCode), strlen(displayCode))))
    {
        /* If an error occurs, get the error message and print it */
        char errorBytes[2048] = {(char) 0};
        JLError_FetchMsgStr(&errorSym, SList_adapt(reinterpret_cast<uint8_t *>(errorBytes), sizeof(errorBytes)));
        printf("error: %s\n", errorBytes);
        return 1;
    }

    std::cout << "Type 'exit' and press Enter to exit" << std::endl;

    while (true)
    {
        std::cout << "julia-demo> ";
        std::getline(std::cin, consoleInput);
        if (consoleInput == "exit")
        {
            break;
        }
        else
        {
            /* Convert the input string to char* and evaluate it */

            char *code = const_cast<char *>(consoleInput.c_str());
            if (ErrorCode::ok != JLEval(&res, NULL, SList_adapt(reinterpret_cast<uint8_t *>(code), strlen(code))))
            {
                char errorBytes[2048] = {(char) 0};
                JLError_FetchMsgStr(&errorSym, SList_adapt(reinterpret_cast<uint8_t *>(errorBytes), sizeof(errorBytes)));
                printf("error: %s\n", errorBytes);
                continue;
            }

            JV jvoid;
            JV arguments[1];
            arguments[0] = res;

            printf("result => \n");
            JLCall(&jvoid, display, SList_adapt(&arguments[0], 1), emptyKwArgs());
            JLFreeFromMe(jvoid);

            /* Release the Julia value referred to by 'res' as it is no longer needed */
            JLFreeFromMe(res);
        }
        std::cout << std::endl;
    }

    /* Release 'display' as it is no longer needed */
    JLFreeFromMe(display);
    exit(0);

    return 0;
}
