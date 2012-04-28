#import <Foundation/Foundation.h>

#import "al_easy_varg.h"

#define ALEasyVarg_CreateArray(firstArgument, outArguments)                                         \
({                                                                                                  \
                                                                                                    \
    __typeof__(firstArgument) *__primitiveArguments = nil;                                          \
    NSArray *__arguments = nil;                                                                     \
    int __numberOfArguments = 0;                                                                    \
    BOOL __result = NO;                                                                             \
                                                                                                    \
        NSCParameterAssert(firstArgument);                                                          \
        NSCParameterAssert(outArguments);                                                           \
                                                                                                    \
    AL_EV_CREATE((firstArgument), nil, &__primitiveArguments, &__numberOfArguments);                \
                                                                                                    \
        ALAssertOrPerform(__primitiveArguments, goto __cleanup);                                    \
                                                                                                    \
    __arguments = [NSArray arrayWithObjects: __primitiveArguments count: __numberOfArguments];      \
                                                                                                    \
    __result = YES;                                                                                 \
                                                                                                    \
    __cleanup:                                                                                      \
    {                                                                                               \
                                                                                                    \
        if (__primitiveArguments)                                                                   \
            AL_EV_CLEANUP(__primitiveArguments),                                                    \
            __primitiveArguments = nil;                                                             \
                                                                                                    \
        /* Fill our output variables. */                                                            \
                                                                                                    \
        if (__result)                                                                               \
            *(outArguments) = __arguments;                                                          \
                                                                                                    \
    }                                                                                               \
                                                                                                    \
})