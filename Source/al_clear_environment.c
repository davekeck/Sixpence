#include "al_clear_environment.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#pragma mark -
#pragma mark Function Implementations
#pragma mark -

bool al_clear_environment(void)
{

    /* We're using uint32_t here for i, just so that we're compatible with al_save...() and al_load...(), above (since that's what they use.) */
    
    char **environment = NULL;
    bool result = false;
    
    for (;;)
    {
    
        char *strrchr_result = NULL,
             *environment_variable_key_string = NULL;
        size_t environment_variable_key_string_length = 0;
        int unsetenv_result = 0;
        bool loop_result = false;
        
        /* We have to get our environment again through each pass, since we're modifying it on each iteration. */
        
        environment = al_environ();
        
            AL_ASSERT_OR_PERFORM(environment, goto loop_cleanup);
            
            /* If our current environment key is NULL, then our environment is empty: we're finished! */
            
            if (!environment[0])
                break;
        
        strrchr_result = strchr(environment[0], '=');
        
            AL_ASSERT_OR_PERFORM(strrchr_result, goto loop_cleanup);
        
        /* Allocate our resulting key/value strings. */
        
        environment_variable_key_string_length = (strrchr_result - environment[0]);
        
            /* We don't allow key lengths being 0. */
            
            AL_ASSERT_OR_PERFORM(environment_variable_key_string_length, goto loop_cleanup);
        
        environment_variable_key_string = malloc(environment_variable_key_string_length + 1);
        
            AL_ASSERT_OR_PERFORM(environment_variable_key_string, goto loop_cleanup);
        
        memcpy(environment_variable_key_string, environment[0], environment_variable_key_string_length);
        environment_variable_key_string[environment_variable_key_string_length] = 0;
        
        /* Unset the current environment variable. */
        
        unsetenv_result = unsetenv(environment_variable_key_string);
        
            AL_ASSERT_OR_PERFORM(!unsetenv_result, goto loop_cleanup);
        
        /* If we make it here, the current iteration succeeded! */
        
        loop_result = true;
        
        loop_cleanup:
        {
        
            if (environment_variable_key_string)
                free(environment_variable_key_string),
                environment_variable_key_string = NULL;
        
        }
        
        if (!loop_result)
            goto cleanup;
    
    }
    
    result = true;
    
    cleanup:
    {
    }
    
    return result;

}