#include "al_copy_more_data.h"

#include <assert.h>
#include <string.h>

bool al_cmd_can_copy_more_data(size_t destination_length, size_t destination_offset, size_t source_length, size_t source_offset, size_t copy_length)
{

        /* Verify that `destination_offset` won't overflow when we add `copy_length` to it. ### This check needs to come before the one following
           it, where we actually add `copy_length` to `destination_offset`, and assume that it doesn't overflow.*/
        
        AL_CONFIRM_OR_PERFORM((AL_INT_MAX_VALUE_FOR_OBJECT(destination_offset) - destination_offset) >= copy_length, return false);
        
        /* Verify that we're reading entirely within the bounds of the destination buffer. */
        
        AL_CONFIRM_OR_PERFORM((destination_offset + copy_length) <= destination_length, return false);
        
        /* Verify that `source_offset` won't overflow when we add `copy_length` to it. ### This check needs to come before the one following
           it, where we actually add `copy_length` to `source_offset`, and assume that it doesn't overflow. */
        
        AL_CONFIRM_OR_PERFORM((AL_INT_MAX_VALUE_FOR_OBJECT(source_offset) - source_offset) >= copy_length, return false);
        
        /* Verify that we're reading entirely within the bounds of the source buffer. */
        
        AL_CONFIRM_OR_PERFORM((source_offset + copy_length) <= source_length, return false);
    
    return true;

}

bool al_cmd_copy_more_data(void *destination, size_t destination_length, size_t *in_out_destination_offset,
    const void *source, size_t source_length, size_t *in_out_source_offset, size_t copy_length)
{

    size_t destination_offset = 0,
           source_offset = 0;
    
        assert(destination);
        assert(source);
    
    destination_offset = (in_out_destination_offset ? *in_out_destination_offset : 0);
    source_offset = (in_out_source_offset ? *in_out_source_offset : 0);
    
        AL_CONFIRM_OR_PERFORM(al_cmd_can_copy_more_data(destination_length, destination_offset, source_length, source_offset, copy_length), return false);
    
    /* Do the copy! */
    
    memmove((destination + destination_offset), (source + source_offset), copy_length);
    
    /* Supply the caller with updated offsets. ### Note that we're not simply using the += operator, due to the case
       where `in_out_destination_offset` == `in_out_source_offset`, which would lead to adding `copy_length` twice
       (and could potentially overflow too!) */
    
    if (in_out_destination_offset)
        *in_out_destination_offset = (destination_offset + copy_length);
    
    if (in_out_source_offset)
        *in_out_source_offset = (source_offset + copy_length);
    
    return true;

}