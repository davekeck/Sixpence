#include "al_modify_descriptor_flags.h"

#include <stdio.h>
#include <assert.h>

#pragma mark Function Implmentations
#pragma mark -

bool al_mdf_modify_descriptor_flags(int descriptor, al_mdf_operation operation, al_mdf_fcntl_command fcntl_command, int change_flags, int *out_original_flags)
{

    int fcntl_get_command = 0,
        fcntl_set_command = 0,
        original_flags = 0,
        new_flags = 0,
        fcntl_result = 0;
    
        /* Verify our arguments. */
        
        assert(AL_VALUE_IN_RANGE_EXCLUSIVE(operation, _al_mdf_operation_first, _al_mdf_operation_length));
        assert(AL_VALUE_IN_RANGE_EXCLUSIVE(fcntl_command, _al_mdf_fcntl_command_first, _al_mdf_fcntl_command_length));
    
    /* Determine our fcntl commands based on the supplied fcntl_command. */
    
    if (fcntl_command == al_mdf_fcntl_command_fl)
    {
    
        fcntl_get_command = F_GETFL;
        fcntl_set_command = F_SETFL;
    
    }
    
    else if (fcntl_command == al_mdf_fcntl_command_fd)
    {
    
        fcntl_get_command = F_GETFD;
        fcntl_set_command = F_SETFD;
    
    }
    
    fcntl_result = fcntl(descriptor, fcntl_get_command);
    
        /* Note that we're explicitly checking for -1, because fcntl() returns all sorts of values, but -1 is reserved for errors. */
        
        AL_ASSERT_OR_PERFORM(fcntl_result != -1, return false);
    
    original_flags = fcntl_result;
    
    if (operation == al_mdf_operation_set)
        new_flags = change_flags;
    
    else if (operation == al_mdf_operation_enable)
        new_flags = (original_flags | change_flags);
    
    else if (operation == al_mdf_operation_disable)
        new_flags = (original_flags & ~change_flags);
    
    fcntl_result = fcntl(descriptor, fcntl_set_command, new_flags);
    
        /* Note that we're explicitly checking for -1, because fcntl() returns all sorts of values, but -1 is reserved for errors. */
        
        AL_ASSERT_OR_PERFORM(fcntl_result != -1, return false);
    
    if (out_original_flags)
        *out_original_flags = original_flags;
    
    return true;

}