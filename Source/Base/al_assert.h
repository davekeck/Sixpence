#pragma once
#include <TargetConditionals.h>

#if (TARGET_OS_MAC && !TARGET_OS_IPHONE)

    /* OS X */
    
    #if (!defined(KERNEL) || !KERNEL)
    
        /* Userspace-only */
        
        #include <stdlib.h>
        #include <stdio.h>
        #include <unistd.h>
        #include <stdbool.h>
        #include <time.h>
        
        #define AL_ASSERT_MESSAGE_FORMAT "%s Assertion failed (process name: %s, pid: %d, file: %s, function: %s, line: %llu): %s\n"
        #define AL_ASSERT_OR_ABORT(condition) AL_ASSERT_OR_PERFORM((condition), abort())
        #define AL_ASSERT_OR_PERFORM(condition, action)                                                                                 \
        ({                                                                                                                              \
                                                                                                                                        \
            bool ___evaluated_condition = false;                                                                                        \
                                                                                                                                        \
            ___evaluated_condition = (bool)(condition);                                                                                 \
                                                                                                                                        \
            if (!___evaluated_condition)                                                                                                \
            {                                                                                                                           \
                                                                                                                                        \
                time_t ___current_time = 0;                                                                                             \
                const char *___current_time_string = NULL;                                                                              \
                int ___argc = 0;                                                                                                        \
                char **___argv = NULL;                                                                                                  \
                                                                                                                                        \
                ___current_time = time(NULL);                                                                                           \
                ___current_time_string = ctime(&___current_time);                                                                       \
                                                                                                                                        \
                if (!___current_time_string)                                                                                            \
                    ___current_time_string = "(unknown time)";                                                                          \
                                                                                                                                        \
                ___argc = al_argc();                                                                                                    \
                ___argv = al_argv();                                                                                                    \
                                                                                                                                        \
                fprintf(stderr, AL_ASSERT_MESSAGE_FORMAT, ___current_time_string, (___argc && ___argv ? ___argv[0] : "(unknown)"),      \
                    getpid(), __FILE__, __PRETTY_FUNCTION__, (unsigned long long)__LINE__, (#condition));                               \
                                                                                                                                        \
                action;                                                                                                                 \
                                                                                                                                        \
            }                                                                                                                           \
                                                                                                                                        \
        })

    #else

        /* Kernelspace-only */
        
        #include <libkern/libkern.h>
        
        #define AL_ASSERT_MESSAGE_FORMAT "Assertion failed (kernel process, file: %s, function: %s, line: %llu): %s\n"
        #define AL_ASSERT_OR_PERFORM(condition, action)                                                                           \
        ({                                                                                                                        \
                                                                                                                                  \
            bool ___evaluated_condition = false;                                                                                  \
                                                                                                                                  \
            ___evaluated_condition = (bool)(condition);                                                                           \
                                                                                                                                  \
            if (!___evaluated_condition)                                                                                          \
            {                                                                                                                     \
                                                                                                                                  \
                printf(AL_ASSERT_MESSAGE_FORMAT, __FILE__, __PRETTY_FUNCTION__, (unsigned long long)__LINE__, (#condition));      \
                                                                                                                                  \
                action;                                                                                                           \
                                                                                                                                  \
            }                                                                                                                     \
                                                                                                                                  \
        })

    #endif

#elif (TARGET_OS_MAC && TARGET_OS_IPHONE)

    /* Userspace iOS */
    
    #include <stdlib.h>
    #include <stdio.h>
    #include <unistd.h>
    #include <stdbool.h>
    #include <time.h>
    
    #define AL_ASSERT_MESSAGE_FORMAT "%s Assertion failed (pid: %d, file: %s, function: %s, line: %llu): %s\n"
    #define AL_ASSERT_OR_ABORT(condition) AL_ASSERT_OR_PERFORM((condition), abort())
    #define AL_ASSERT_OR_PERFORM(condition, action)                                                    \
    ({                                                                                                 \
                                                                                                       \
        bool ___evaluated_condition = false;                                                           \
                                                                                                       \
        ___evaluated_condition = (bool)(condition);                                                    \
                                                                                                       \
        if (!___evaluated_condition)                                                                   \
        {                                                                                              \
                                                                                                       \
            time_t ___current_time = 0;                                                                \
            const char *___current_time_string = NULL;                                                 \
                                                                                                       \
            ___current_time = time(NULL);                                                              \
            ___current_time_string = ctime(&___current_time);                                          \
                                                                                                       \
            if (!___current_time_string)                                                               \
                ___current_time_string = "(unknown time)";                                             \
                                                                                                       \
            fprintf(stderr, AL_ASSERT_MESSAGE_FORMAT, ___current_time_string, getpid(), __FILE__,      \
                __PRETTY_FUNCTION__, (unsigned long long)__LINE__, (#condition));                      \
                                                                                                       \
            action;                                                                                    \
                                                                                                       \
        }                                                                                              \
                                                                                                       \
    })

#endif