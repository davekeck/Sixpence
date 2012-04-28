#include "al_argv.h"

/* We're including stdio for NULL. */

#include <stdio.h>
#include <crt_externs.h>

char **al_argv(void)
{

    char ***get_argv_result = NULL;
    
    get_argv_result = _NSGetArgv();
    
        /* Can't use AL_ASSERT_() here because it uses this function, so if this function fails, we'd get a stack overflow. */
        
        AL_CONFIRM_OR_PERFORM(get_argv_result, return NULL);
    
    return (*get_argv_result);

}

int al_argc(void)
{

    int *get_argc_result = NULL;
    
    get_argc_result = _NSGetArgc();
    
        /* Can't use AL_ASSERT_() here because it uses this function, so if this function fails, we'd get a stack overflow. */
        
        AL_CONFIRM_OR_PERFORM(get_argc_result, return -1);
    
    return (*get_argc_result);

}

char **al_environ(void)
{

    char ***get_environ_result = NULL;
    
    get_environ_result = _NSGetEnviron();
    
        /* Can't use AL_ASSERT_() here because it uses this function, so if this function fails, we'd get a stack overflow. */
        
        AL_CONFIRM_OR_PERFORM(get_environ_result, return NULL);
    
    return (*get_environ_result);

}