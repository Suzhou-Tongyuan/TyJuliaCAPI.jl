#include "tyjuliacapi.hpp"
#include <string.h>
#include <stdio.h>

/* Exported functions in a DLL should be decorated with the DLL_EXPORT macro */

// The evaluateAndGetRank() function takes a block of Julia code and returns the rank of the resulting array
DLLEXPORT int evaluateAndGetRank(char* code) {
    JV res;
    JSym errorSym;
    char errorBytes[2048];

    /* Execute the Julia code stored in the 'code' variable in the Main module */
    if (ErrorCode::ok != JLEval(&res, NULL, SList_adapt(reinterpret_cast<uint8_t*>(code), strlen(code)))) {
        JLError_FetchMsgStr(&errorSym, SList_adapt(reinterpret_cast<uint8_t*>(errorBytes), sizeof(errorBytes)));
        printf("error: %s\n", errorBytes);
        return 1;
    }

    int64_t rank;
    if (ErrorCode::ok != JLArray_Rank(&rank, res)) {
        JLError_FetchMsgStr(&errorSym, SList_adapt(reinterpret_cast<uint8_t*>(errorBytes), sizeof(errorBytes)));
        printf("error: %s\n", errorBytes);
        return 1;
    }
    printf("The rank of the computed array is: %d\n", rank);
    JLFreeFromMe(res);

    return 0;
}
