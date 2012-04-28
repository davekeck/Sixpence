#pragma once
#include <stdlib.h>
#include <stdbool.h>
#include <stdarg.h>
#include <assert.h>

/* This macro turns a variable argument list into an array.
   
       first_argument: the argument that preceeds the variable argument list.
                 type: any.
       
       terminator: the value of the terminating argument (typically 0 or NULL.)
             type: same type as first_argument.
       
       out_arguments: a pointer to the argument array. This array includes the terminator.
                type: must be a pointer to a pointer to a variable whose type that matches first_argument.
       
       out_number_of_arguments: the number of arguments in the out_arguments array (not including the terminator.) Can be NULL.
                          type: int.
   
   If an error occurs, *out_arguments == NULL. (*out_arguments will always be non-NULL if it succeeds, because a terminator is
   always present in the resulting *out_arguments.)

*/

#define AL_EV_CREATE(first_argument, terminator, out_arguments, out_number_of_arguments)                                    \
({                                                                                                                          \
                                                                                                                            \
    va_list ___argument_list;                                                                                               \
    __typeof__(first_argument) *___arguments = NULL;                                                                        \
    __typeof__(first_argument) ___current_argument;                                                                         \
    int ___i = 0,                                                                                                           \
        ___number_of_arguments = 0;                                                                                         \
    bool ___result = false;                                                                                                 \
                                                                                                                            \
        /* Verify our arguments. */                                                                                         \
                                                                                                                            \
        assert(out_arguments);                                                                                              \
                                                                                                                            \
    va_start(___argument_list, (first_argument));                                                                           \
                                                                                                                            \
    /* Loop through our arguments and add them to the array. */                                                             \
                                                                                                                            \
    for (___current_argument = (first_argument), ___i = 0;; ___i++)                                                         \
    {                                                                                                                       \
                                                                                                                            \
        ___arguments = (__typeof__(___arguments))reallocf((void *)___arguments, (sizeof(*___arguments) * (___i + 1)));      \
                                                                                                                            \
            AL_ASSERT_OR_PERFORM(___arguments, goto ___cleanup);                                                            \
                                                                                                                            \
        ___arguments[___i] = ___current_argument;                                                                           \
                                                                                                                            \
            if (___current_argument == (terminator))                                                                        \
                break;                                                                                                      \
                                                                                                                            \
        ___current_argument = va_arg(___argument_list, __typeof__(first_argument));                                         \
        ___number_of_arguments++;                                                                                           \
                                                                                                                            \
    }                                                                                                                       \
                                                                                                                            \
    ___result = true;                                                                                                       \
                                                                                                                            \
    ___cleanup:                                                                                                             \
    {                                                                                                                       \
                                                                                                                            \
        if (!___result)                                                                                                     \
        {                                                                                                                   \
                                                                                                                            \
            free(___arguments),                                                                                             \
            ___arguments = NULL;                                                                                            \
                                                                                                                            \
        }                                                                                                                   \
                                                                                                                            \
        va_end(___argument_list);                                                                                           \
                                                                                                                            \
        /* Fill our output variables. */                                                                                    \
                                                                                                                            \
        if (___result)                                                                                                      \
        {                                                                                                                   \
                                                                                                                            \
            *(out_arguments) = ___arguments;                                                                                \
                                                                                                                            \
            if (out_number_of_arguments)                                                                                    \
            {                                                                                                               \
                                                                                                                            \
                /* We're doing this indirection to avoid a compiler warning that we're dereferencing NULL. */               \
                                                                                                                            \
                int *___out_number_of_arguments = NULL;                                                                     \
                                                                                                                            \
                ___out_number_of_arguments = out_number_of_arguments;                                                       \
                *___out_number_of_arguments = ___number_of_arguments;                                                       \
                                                                                                                            \
            }                                                                                                               \
                                                                                                                            \
        }                                                                                                                   \
                                                                                                                            \
    }                                                                                                                       \
                                                                                                                            \
})

#define AL_EV_CLEANUP(arguments)      \
({                                    \
                                      \
        assert(arguments);            \
                                      \
    free((void *)arguments);          \
                                      \
})