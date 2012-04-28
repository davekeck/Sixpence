#include "al_wait_for_process.h"

#include <unistd.h>
#include <sys/wait.h>
#include <sys/event.h>
#include <errno.h>
#include <assert.h>
#include <stdio.h>
#include <signal.h>

#include "al_modify_descriptor_flags.h"

al_wfp_result_t al_wfp_wait_for_process_termination(pid_t process_id, double timeout)
{

    al_descriptor_t kernel_queue = al_descriptor_init;
    int kevent_result = 0;
    bool set_close_on_exec_result = false;
    struct kevent kernel_filter;
    double start_time = 0.0;
    struct timespec kevent_timeout,
                    *kevent_timeout_argument = NULL;
    al_wfp_result_t result = al_wfp_result_init;
    
    result = al_wfp_result_error;
    
    kernel_queue.descriptor = kqueue();
    kernel_queue.valid = (kernel_queue.descriptor != -1);
    
        AL_ASSERT_OR_PERFORM(kernel_queue.valid, goto cleanup);
    
    set_close_on_exec_result = al_mdf_set_descriptor_close_on_exec(kernel_queue.descriptor, true);
    
        AL_ASSERT_OR_PERFORM(set_close_on_exec_result, goto cleanup);
    
    /* Set up our filter on the kqueue. */
    
    EV_SET(&kernel_filter, process_id, EVFILT_PROC, (EV_ADD | EV_RECEIPT), NOTE_EXIT, 0, NULL);
    
    do
    {
    
        errno = 0;
        kevent_result = kevent(kernel_queue.descriptor, &kernel_filter, 1, &kernel_filter, 1, NULL);
    
    } while (kevent_result == -1 && errno == EINTR);
    
        /* Verify that exactly one filter was applied to the kqueue. Since we used the EV_RECEIPT flag, if the filter was added
           successfully, its 'flags' element will have the EV_ERROR bit set, and kernel_filter.data will be 0. */
        
        AL_ASSERT_OR_PERFORM(kevent_result == 1, goto cleanup);
        AL_ASSERT_OR_PERFORM((kernel_filter.flags & EV_ERROR), goto cleanup);
        AL_ASSERT_OR_PERFORM(!kernel_filter.data || kernel_filter.data == ESRCH, goto cleanup);
        
        if (kernel_filter.data == ESRCH)
        {
        
            result = al_wfp_result_process_doesnt_exist_error;
            goto cleanup;
        
        }
    
    /* Start waiting for the process to exit, or for the timeout to elapse. */
    
    if (timeout >= 0.0)
    {
    
        kevent_timeout_argument = &kevent_timeout;
        start_time = al_time_current_time();
    
    }
    
    for (;;)
    {
    
        struct kevent kernel_event;
        
        /* Update our timepsec timeout variable (if we have a timeout that is; ie, if timeout >= 0.0.) */
        
        if (timeout >= 0.0)
            kevent_timeout = al_time_convert_time_to_timespec(al_time_remaining_timeout(start_time, timeout));
        
        errno = 0;
        kevent_result = kevent(kernel_queue.descriptor, NULL, 0, &kernel_event, 1, kevent_timeout_argument);
        
            AL_ASSERT_OR_PERFORM(kevent_result == 1 || !kevent_result || (kevent_result == -1 && errno == EINTR), goto cleanup);
        
        if (kevent_result == 1)
        {
        
                AL_ASSERT_OR_PERFORM(kernel_event.ident == process_id, goto cleanup);
                AL_ASSERT_OR_PERFORM(kernel_event.filter == EVFILT_PROC, goto cleanup);
                AL_ASSERT_OR_PERFORM(kernel_event.fflags & NOTE_EXIT, goto cleanup);
            
            result = al_wfp_result_process_terminated;
            break;
        
        }
        
        else if (!kevent_result || al_time_timeout_has_elapsed(start_time, timeout))
        {
        
            result = al_wfp_result_timeout_elapsed;
            break;
        
        }
    
    }
    
    cleanup:
    {
    
        al_descriptor_cleanup(&kernel_queue, AL_NO_OP);
    
    }
    
    return result;

}

bool al_wfp_wait_for_process_status(pid_t process_id, int waitpid_options, int *out_process_status)
{

    int process_status = 0,
        waitpid_result = 0;
    bool result = false;
    
    /* Attempt to get the child's status. Note that we're doing this fancy loop because if waitpid() is interrupted
       by a signal, it'll return an error with errno == EINTR. So we'll keep trying until this isn't the case. */
    
    do
    {
    
        errno = 0;
        waitpid_result = waitpid(process_id, &process_status, waitpid_options);
    
    } while (waitpid_result == -1 && errno == EINTR);
    
        /* If we end up here and the waitpid()'s return value != our specified child process' PID, then we're erroring-out. */
        
        AL_ASSERT_OR_PERFORM(waitpid_result == process_id, goto cleanup);
    
    /* If we make it here, we were successful! */
    
    result = true;
    
    cleanup:
    {
    
        /* Fill our output variables. */
        
        if (result)
        {
        
            /* Only if we were successful are we going to fill *out_process_status. */
            
            if (out_process_status)
                *out_process_status = process_status;
        
        }
    
    }
    
    return result;

}

bool al_wfp_kill_and_reap_process(pid_t process_id, bool always_reap)
{

    int kill_result = 0;
    
    errno = 0;
    kill_result = kill(process_id, SIGKILL);
    
    if (!kill_result || (kill_result == -1 && errno == ESRCH) || always_reap)
    {
    
        bool wait_for_process_status_result = false;
        
        wait_for_process_status_result = al_wfp_wait_for_process_status(process_id, 0, NULL);
        
            AL_ASSERT_OR_PERFORM(wait_for_process_status_result, return false);
        
        return true;
    
    }
    
    return false;

}