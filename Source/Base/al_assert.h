#pragma once
#include <TargetConditionals.h>

#if (TARGET_OS_MAC && !TARGET_OS_IPHONE)

    /* OS X */
    #if (!defined(KERNEL) || !KERNEL)
    
        /* Userspace-only */
        #include <stdlib.h>
        #include <stdio.h>
        #include <stdint.h>
        #include <stdbool.h>
        #include <unistd.h>
        #include <time.h>
        #include <libgen.h>
        #include <string.h>
        
        #define AL_ASSERT_MESSAGE_FORMAT "=== Assertion failed ===\n  Time: %s  Process: %s (%jd)\n  File: %s:%ju\n  Function: %s\n  Assertion: %s\n"
        #define AL_ASSERT_OR_ABORT(condition) AL_ASSERT_OR_PERFORM((condition), abort())
        #define AL_ASSERT_OR_PERFORM(condition, action)                                                                    \
        ({                                                                                                                 \
            bool ___evaluated_condition = (bool)(condition);                                                               \
            if (!___evaluated_condition)                                                                                   \
            {                                                                                                              \
                time_t ___current_time = time(NULL);                                                                       \
                const char *___current_time_string = ctime(&___current_time);                                              \
                if (!___current_time_string)                                                                               \
                    ___current_time_string = "(unknown)";                                                                  \
                                                                                                                           \
                int ___argc = al_argc();                                                                                   \
                char **___argv = al_argv();                                                                                \
                char *___process_name = strdup(___argc && ___argv ? basename(___argv[0]) : "(unknown)");                   \
                char *___file_name = strdup(basename(__FILE__));                                                           \
                                                                                                                           \
                fprintf(stderr, AL_ASSERT_MESSAGE_FORMAT, ___current_time_string, ___process_name, (intmax_t)getpid(),     \
                    ___file_name, (uintmax_t)__LINE__, __PRETTY_FUNCTION__, (#condition));                                 \
                                                                                                                           \
                action;                                                                                                    \
                                                                                                                           \
                free(___process_name),                                                                                     \
                ___process_name = NULL;                                                                                    \
                                                                                                                           \
                free(___file_name),                                                                                        \
                ___file_name = NULL;                                                                                       \
            }                                                                                                              \
        })

    #else

        /* Kernelspace-only */
        #include <libkern/libkern.h>
        #include <stdint.h>
        
        #define AL_ASSERT_MESSAGE_FORMAT "=== Assertion failed ===\n  File: %s:%ju\n  Function: %s\n  Assertion: %s\n"
        #define AL_ASSERT_OR_PERFORM(condition, action)                                                                  \
        ({                                                                                                               \
            bool ___evaluated_condition = (bool)(condition);                                                             \
            if (!___evaluated_condition)                                                                                 \
            {                                                                                                            \
                printf(AL_ASSERT_MESSAGE_FORMAT, __FILE__, (uintmax_t)__LINE__, __PRETTY_FUNCTION__, (#condition));      \
                action;                                                                                                  \
            }                                                                                                            \
        })

    #endif

#elif (TARGET_OS_MAC && TARGET_OS_IPHONE)

    /* iOS */
    #include <stdlib.h>
    #include <stdio.h>
    #include <stdint.h>
    #include <stdbool.h>
    #include <unistd.h>
    #include <time.h>
    #include <libgen.h>
    #include <string.h>
    
    #define AL_ASSERT_MESSAGE_FORMAT "=== Assertion failed ===\n  Time: %s  PID: %jd\n  File: %s:%ju\n  Function: %s\n  Assertion: %s\n"
    #define AL_ASSERT_OR_ABORT(condition) AL_ASSERT_OR_PERFORM((condition), abort())
    #define AL_ASSERT_OR_PERFORM(condition, action)                                                   \
    ({                                                                                                \
        bool ___evaluated_condition = (bool)(condition);                                              \
        if (!___evaluated_condition)                                                                  \
        {                                                                                             \
            time_t ___current_time = time(NULL);                                                      \
            const char *___current_time_string = ctime(&___current_time);                             \
            if (!___current_time_string)                                                              \
                ___current_time_string = "(unknown)";                                                 \
                                                                                                      \
            char *___file_name = strdup(basename(__FILE__));                                          \
                                                                                                      \
            fprintf(stderr, AL_ASSERT_MESSAGE_FORMAT, ___current_time_string, (intmax_t)getpid(),     \
                ___file_name, (uintmax_t)__LINE__, __PRETTY_FUNCTION__, (#condition));                \
                                                                                                      \
            action;                                                                                   \
                                                                                                      \
            free(___file_name),                                                                       \
            ___file_name = NULL;                                                                      \
        }                                                                                             \
    })

#endif