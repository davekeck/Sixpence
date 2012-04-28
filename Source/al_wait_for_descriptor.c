#include "al_wait_for_descriptor.h"

#include <sys/select.h>
#include <stddef.h>
#include <errno.h>
#include <assert.h>

const double al_wfd_maximum_timeout = (60 * 60 * 24 * 365);

al_wfd_result_t al_wfd_wait_for_descriptor(int descriptor, al_wfd_event_type_t event_type, double timeout)
{

    double start_time = 0.0;
    struct timespec select_timeout,
                    *select_timeout_argument = NULL;
    al_wfd_result_t result = al_wfd_result_init;
    
        /* Verify our arguments. */
        
        assert(AL_VALUE_IN_RANGE_EXCLUSIVE(event_type, _al_wfd_event_type_first, _al_wfd_event_type_length));
        assert(timeout <= al_wfd_maximum_timeout);
    
    /* By default, we're assuming an error occurred. */
    
    result = al_wfd_result_error;
    
    /* If we have a timeout, then select() requires a timeval argument. Otherwise, we wait indefinitely by giving select() a NULL.
       Note that our loop actually calculates our select_timeout as it runs. */
    
    if (timeout >= 0.0)
    {
    
        select_timeout_argument = &select_timeout;
        start_time = al_time_current_time();
    
    }
    
    for (;;)
    {
    
        fd_set descriptor_set;
        int select_result = 0;
        
        /* Reset the file descriptor set. */
        
        FD_ZERO(&descriptor_set);
        FD_SET(descriptor, &descriptor_set);
        
        /* Update our timeval timeout variable (if we have a timeout that is; ie, if timeout >= 0.0.) */
        
        if (timeout >= 0.0)
            select_timeout = al_time_convert_time_to_timespec(al_time_remaining_timeout(start_time, timeout));
        
        /* Block until the event occurs or our timeout elapses. */
        
        errno = 0;
        select_result = pselect(descriptor + 1, (event_type == al_wfd_event_type_read ? &descriptor_set : NULL),
            (event_type == al_wfd_event_type_write ? &descriptor_set : NULL),
                (event_type == al_wfd_event_type_error ? &descriptor_set : NULL), select_timeout_argument, NULL);
        
            /* Inspect the result of our select() to determine whether we're failing immediately. Note that we permit
               select_result == -1 if errno == EAGAIN or EINTR. */
            
            AL_ASSERT_OR_PERFORM((select_result == 1 && FD_ISSET(descriptor, &descriptor_set)) || !select_result ||
                (select_result == -1 && (errno == EAGAIN || errno == EINTR)), goto cleanup);
        
        /* If select() reported that the specified descriptor event occurred, then it's time to break and tell our caller. */
        
        if (select_result == 1)
        {
        
            result = al_wfd_result_event_occurred;
            break;
        
        }
        
        /* Otherwise, if select() reported that our timeout elapsed, then we'll bail and let the caller know. We're also checking the timeout
           explicitly, due to an edge case explained in al_perform_fd_operation.c at the end of the for loop. */
        
        else if (!select_result || al_time_timeout_has_elapsed(start_time, timeout))
        {
        
            result = al_wfd_result_timeout_elapsed;
            break;
        
        }
    
    }
    
    cleanup:
    {
    }
    
    return result;

}