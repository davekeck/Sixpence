#include "al_spawn_process.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <signal.h>
#include <errno.h>
#include <sys/wait.h>
#include <assert.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <pthread.h>
#include <sys/event.h>

#include "al_wait_for_process.h"
#include "al_easy_varg.h"
#include "al_modify_descriptor_flags.h"

#pragma mark Public Constants
#pragma mark -

const al_descriptor_t al_sp_standard_descriptors_inherit[] = {{.valid = false}};
const al_descriptor_t al_sp_standard_descriptors_null[] = {{.valid = false}};

#pragma mark Private Function Interfaces
#pragma mark -

static al_pid_t al_sp_fork_process(const char *const arguments[], const char *const environment[], const al_descriptor_t standard_descriptors[],
    const al_descriptor_t other_descriptors[], al_uid_t user_id, al_gid_t group_id);
static bool al_sp_wait_for_process_termination(pid_t process_id, double timeout, bool *out_process_terminated, int *out_process_status);
static al_descriptor_t al_sp_safe_dup(int descriptor);

#pragma mark -
#pragma mark Function Implementations
#pragma mark -

al_sp_result_t al_sp_spawn_process_va(const char *const environment[], const al_descriptor_t standard_descriptors[],
    const al_descriptor_t other_descriptors[], al_uid_t user_id, al_gid_t group_id, double timeout, pid_t *out_process_id, int *out_process_status,
    const char *first_argument, ...)
{

    const char *const *arguments = NULL;
    al_sp_result_t result = al_sp_result_init;
    
        /* Verify our arguments. */
        
        assert(first_argument && strlen(first_argument));
    
    result = al_sp_result_error;
    
    /* Create our arguments array. */
    
    AL_EV_CREATE(first_argument, NULL, &arguments, NULL);
    
        AL_ASSERT_OR_PERFORM(arguments, goto cleanup);
    
    result = al_sp_spawn_process(arguments, environment, standard_descriptors, other_descriptors, user_id, group_id,
        timeout, out_process_id, out_process_status);
    
    cleanup:
    {
    
        if (arguments)
            AL_EV_CLEANUP(arguments),
            arguments = NULL;
    
    }
    
    return result;

}

al_sp_result_t al_sp_spawn_process(const char *const arguments[], const char *const environment[], const al_descriptor_t standard_descriptors[],
    const al_descriptor_t other_descriptors[], al_uid_t user_id, al_gid_t group_id, double timeout, pid_t *out_process_id, int *out_process_status)
{

    struct stat executable_file_info;
    int stat_result = 0,
        process_status = 0,
        i = 0;
    al_pid_t process_id;
    al_sp_result_t result = al_sp_result_init;
    
        /* Verify our arguments. */
        
        assert(arguments && arguments[0] && strlen(arguments[0]));
        
        assert(standard_descriptors);
        for (i = 0; standard_descriptors != al_sp_standard_descriptors_inherit &&
            standard_descriptors != al_sp_standard_descriptors_null && i < 3; i++) assert(standard_descriptors[i].valid);
    
    /* Initialize our variables. */
    
    result = al_sp_result_error;
    
    /* First, verify that the executable exists. */
    
    stat_result = stat(arguments[0], &executable_file_info);
    
        AL_ASSERT_OR_PERFORM(!stat_result, goto cleanup);
        AL_ASSERT_OR_PERFORM(S_ISREG(executable_file_info.st_mode), goto cleanup);
    
    process_id = al_sp_fork_process(arguments, environment, standard_descriptors, other_descriptors, user_id, group_id);
    
        AL_ASSERT_OR_PERFORM(process_id.valid, goto cleanup);
    
    /* If the supplied timeout isn't our special "don't wait" value (0.0), then we'll wait for the child process to terminate, or for the timeout
       to elapse. */
    
    if (timeout != 0.0)
    {
    
        bool process_terminated = false,
             wait_for_process_termination_result = false;
        
        wait_for_process_termination_result = al_sp_wait_for_process_termination(process_id.pid, timeout, &process_terminated, &process_status);
        
            AL_ASSERT_OR_PERFORM(wait_for_process_termination_result, result = al_sp_result_wait_error; goto cleanup);
        
        if (!process_terminated)
            result = al_sp_result_process_spawned;
        
        else
            result = al_sp_result_process_terminated;
    
    }
    
    else
        result = al_sp_result_process_spawned;
    
    cleanup:
    {
    
        /* Fill our output variables. */
        
        if (result == al_sp_result_process_spawned || result == al_sp_result_wait_error)
        {
        
            if (out_process_id)
                *out_process_id = process_id.pid;
        
        }
        
        else if (result == al_sp_result_process_terminated)
        {
        
            if (out_process_status)
                *out_process_status = process_status;
        
        }
    
    }
    
    return result;

}

#pragma mark -
#pragma mark Private Function Implementations
#pragma mark -

static al_pid_t al_sp_fork_process(const char *const arguments[], const char *const environment[], const al_descriptor_t standard_descriptors[],
    const al_descriptor_t other_descriptors[], al_uid_t user_id, al_gid_t group_id)
{

    al_descriptor_t exec_pipe[2] = {al_descriptor_init, al_descriptor_init},
                    kernel_queue = al_descriptor_init;
    int temp_pipe[2],
        pipe_result = 0,
        kevent_result = 0;
    bool set_close_on_exec_result = false;
    struct kevent kernel_filter,
                  kernel_event;
    ssize_t write_result = 0;
    uint8_t zero_byte = 0;
    al_pid_t child_process_id = al_pid_init,
             result = al_pid_init;
    
    /* Create the pipe to tell our child when it can exec. ### Note that we keep the read end of this pipe open in the parent
       to ensure when we write() to exec_pipe[0], it's impossible for it to generate a SIGPIPE. */
    
    pipe_result = pipe(temp_pipe);
    
        AL_ASSERT_OR_PERFORM(!pipe_result, goto cleanup);
    
    exec_pipe[0] = al_descriptor_create(true, temp_pipe[0]);
    exec_pipe[1] = al_descriptor_create(true, temp_pipe[1]);
    
    set_close_on_exec_result = al_mdf_set_descriptor_close_on_exec(exec_pipe[0].descriptor, true);
    
        AL_ASSERT_OR_PERFORM(set_close_on_exec_result, goto cleanup);
    
    set_close_on_exec_result = al_mdf_set_descriptor_close_on_exec(exec_pipe[1].descriptor, true);
    
        AL_ASSERT_OR_PERFORM(set_close_on_exec_result, goto cleanup);
    
    /* Create our child process. */
    
    child_process_id.pid = fork(),
    child_process_id.valid = (child_process_id.pid != -1);
    
        AL_ASSERT_OR_PERFORM(child_process_id.valid, goto cleanup);
    
    if (!child_process_id.pid)
    {
    
        /* We're the child.
           
           ### Note that we use AL_CONFIRM... here instead of AL_ASSERT... because we're limited to async-signal-safe
               functions between fork() and exec(). */
        
        static const char *const k_null_environment[] = {NULL};
        sigset_t default_signal_mask = 0;
        int sigemptyset_result = 0,
            sigprocmask_result = 0,
            close_result = 0,
            dup2_result = 0,
            i = 0;
        ssize_t read_result = 0;
        
        /* Reset our umask so that files we create don't have write permission for our group or other users. */
        
        umask(S_IWGRP | S_IWOTH);
        
        /* Reset our signals - first our signal mask, then our signal handlers. */
        
        sigemptyset_result = sigemptyset(&default_signal_mask);
        
            AL_CONFIRM_OR_PERFORM(!sigemptyset_result, goto child_failed);
        
        /* Set our signal mask to the empty signal set. */
        
        sigprocmask_result = sigprocmask(SIG_SETMASK, &default_signal_mask, NULL);
        
            AL_CONFIRM_OR_PERFORM(!sigprocmask_result, goto child_failed);
        
        /* There's no signal 0, so we'll start at 1. We're not using the symbolic constant (at the time of writing, SIGHUP)
           since its underlying value could change. */
        
        for (i = 1; i < NSIG; i++)
        {
        
            void *signal_result = 0;
            
            /* Can't change the signal behavior of SIGKILL and SIGSTOP. */
            
            if (i != SIGKILL && i != SIGSTOP)
            {
            
                signal_result = signal(i, SIG_DFL);
                
                    AL_CONFIRM_OR_PERFORM(signal_result != SIG_ERR, goto child_failed);
            
            }
        
        }
        
        /* Handle our various standard IO options. Note that we don't have to explicitly do anything for the _inherit option. */
        
        if (standard_descriptors == al_sp_standard_descriptors_inherit)
        {
        }
        
        else if (standard_descriptors == al_sp_standard_descriptors_null)
        {
        
            static const char *const k_null_device_path = "/dev/null";
            al_descriptor_t null_descriptor = al_descriptor_init,
                            safe_null_descriptor = al_descriptor_init;
            
            null_descriptor.descriptor = open(k_null_device_path, O_RDWR),
            null_descriptor.valid = (null_descriptor.descriptor != -1);
            
                AL_CONFIRM_OR_PERFORM(null_descriptor.valid, goto child_failed);
            
            safe_null_descriptor = al_sp_safe_dup(null_descriptor.descriptor);
            
                AL_CONFIRM_OR_PERFORM(safe_null_descriptor.valid, goto child_failed);
            
            /* We need to close null_descriptor before we start dup2'ing. If we closed null_descriptor after our dup2 loop, one of the dup2() calls could
               have closed null_descriptor (if null_descriptor < 3), and then we'd be closing one of the new descriptors created via dup2. */
            
            close_result = close(null_descriptor.descriptor),
            null_descriptor.valid = false;
            
                AL_CONFIRM_OR_PERFORM(!close_result, goto child_failed);
            
            for (i = 0; i < 3; i++)
            {
            
                dup2_result = dup2(safe_null_descriptor.descriptor, i);
                
                    AL_CONFIRM_OR_PERFORM(dup2_result != -1, goto child_failed);
            
            }
            
            close_result = close(safe_null_descriptor.descriptor),
            safe_null_descriptor.valid = false;
            
                AL_CONFIRM_OR_PERFORM(!close_result, goto child_failed);
        
        }
        
        else
        {
        
            al_descriptor_t safe_standard_descriptors[3];
            
            for (i = 0; i < 3; i++)
            {
            
                safe_standard_descriptors[i] = al_sp_safe_dup(standard_descriptors[i].descriptor);
                
                    AL_CONFIRM_OR_PERFORM(safe_standard_descriptors[i].valid, goto child_failed);
            
            }
            
            for (i = 0; i < 3; i++)
            {
            
                dup2_result = dup2(safe_standard_descriptors[i].descriptor, i);
                
                    AL_CONFIRM_OR_PERFORM(dup2_result != -1, goto child_failed);
                
                close_result = close(safe_standard_descriptors[i].descriptor),
                safe_standard_descriptors[i].valid = false;
                
                    AL_CONFIRM_OR_PERFORM(!close_result, goto child_failed);
            
            }
        
        }
        
        /* Close all file descriptors >= (STDERR_FILENO + 1) that aren't included in other_descriptors.
           
           ### This needs to come after we set up our standard descriptors above, so that we don't close a descriptor that's in
               standard_descriptors but not in other_descriptors.
           
           ### OPEN_MAX seems to be the hard-coded maximum number of descriptors. That is, setrlimit() fails when called
               with a value larger than OPEN_MAX.
           
           ### Note that we avoid closing the read end of exec_pipe (exec_pipe[0]) here, since we need it later. Both ends
               of the pipe are marked close-on-exec though, so it's not necessary that we manually close either. */
        
        for (i = STDERR_FILENO + 1; i < OPEN_MAX; i++)
        {
        
            bool specified_descriptor = false;
            int ii = 0;
            
                AL_CONFIRM_OR_PERFORM(i != exec_pipe[0].descriptor, continue);
            
            /* Determine whether our current descriptor (i) is specified in our list of descriptors not to close (other_descriptors). */
            
            for (ii = 0; other_descriptors && other_descriptors[ii].valid && !specified_descriptor; ii++)
                specified_descriptor = (other_descriptors[ii].descriptor == i);
            
            if (!specified_descriptor)
                close(i);
        
        }
        
        /* If we were told to do so, set our user ID and/or group IDs. */
        
        if (group_id.valid)
        {
        
            int setgid_result = 0;
            
            setgid_result = setgid(group_id.gid);
            
                AL_CONFIRM_OR_PERFORM(!setgid_result, goto child_failed);
        
        }
        
        if (user_id.valid)
        {
        
            int setuid_result = 0;
            
            setuid_result = setuid(user_id.uid);
            
                AL_CONFIRM_OR_PERFORM(!setuid_result, goto child_failed);
        
        }
        
        /* Wait until our parent tells us to exec. */
        
        do
        {
        
            errno = 0;
            read_result = read(exec_pipe[0].descriptor, &zero_byte, sizeof(zero_byte));
        
        } while (read_result == -1 && errno == EINTR);
        
            AL_CONFIRM_OR_PERFORM(read_result == sizeof(zero_byte), goto child_failed);
        
        /* Finally, let's exec! */
        
        execve(arguments[0], (char *const *)arguments, (environment ? (char *const *)environment : (char *const *)k_null_environment));
        
        child_failed:
        {
        
            /* If we get here, something went wrong. :'( */
            
            _exit(1);
        
        }
    
    }
    
    /* Create our kernel queue that we'll use to determine whether the child successfully exec'd. */
    
    kernel_queue.descriptor = kqueue(),
    kernel_queue.valid = (kernel_queue.descriptor != -1);
    
        AL_ASSERT_OR_PERFORM(kernel_queue.valid, goto cleanup);
    
    set_close_on_exec_result = al_mdf_set_descriptor_close_on_exec(kernel_queue.descriptor, true);
    
        AL_ASSERT_OR_PERFORM(set_close_on_exec_result, goto cleanup);
    
    /* Set up our filter on the kqueue. */
    
    EV_SET(&kernel_filter, child_process_id.pid, EVFILT_PROC, (EV_ADD | EV_RECEIPT), (NOTE_EXIT | NOTE_EXEC), 0, NULL);
    
    do
    {
    
        errno = 0;
        kevent_result = kevent(kernel_queue.descriptor, &kernel_filter, 1, &kernel_filter, 1, NULL);
    
    } while (kevent_result == -1 && errno == EINTR);
    
        /* Verify that exactly one filter was applied to the kqueue. Since we used the EV_RECEIPT flag, if the filter was added
           successfully, its 'flags' element will have the EV_ERROR bit set, and kernel_filter.data will be 0. */
        
        AL_ASSERT_OR_PERFORM(kevent_result == 1, goto cleanup);
        AL_ASSERT_OR_PERFORM((kernel_filter.flags & EV_ERROR), goto cleanup);
        AL_ASSERT_OR_PERFORM(!kernel_filter.data, goto cleanup);
    
    /* Once we've configured our kqueue to watch the child process, use our exec_pipe to tell the child that it can go ahead and exec. */
    
    do
    {
    
        errno = 0;
        write_result = write(exec_pipe[1].descriptor, &zero_byte, sizeof(zero_byte));
    
    } while (write_result == -1 && errno == EINTR);
    
        AL_ASSERT_OR_PERFORM(write_result == sizeof(zero_byte), goto cleanup);
    
    /* Wait for the child to either exec or exit. */
    
    do
    {
    
        errno = 0;
        kevent_result = kevent(kernel_queue.descriptor, NULL, 0, &kernel_event, 1, NULL);
    
    } while (kevent_result == -1 && errno == EINTR);
    
        AL_ASSERT_OR_PERFORM(kevent_result == 1, goto cleanup);
        AL_ASSERT_OR_PERFORM(kernel_event.ident == child_process_id.pid, goto cleanup);
        AL_ASSERT_OR_PERFORM(kernel_event.filter == EVFILT_PROC, goto cleanup);
        AL_ASSERT_OR_PERFORM((kernel_event.fflags & NOTE_EXIT) || (kernel_event.fflags & NOTE_EXEC), goto cleanup);
        
        /* Finally, determine whether the child exec'd. */
        
        AL_ASSERT_OR_PERFORM((kernel_event.fflags & NOTE_EXEC), goto cleanup);
    
    result = child_process_id;
    
    cleanup:
    {
    
        al_descriptor_cleanup(&kernel_queue, AL_NO_OP);
        
        /* If we failed but we did fork, then we need to kill and reap the child process. */
        
        if (!result.valid && child_process_id.valid)
        {
        
            bool kill_and_reap_process_result = false;
            
            /* Note that we're supplying false for `always_reap` below; this is because the child may have fudged with its UID/GID
               credentials, which could prevent us from sending it a SIGKILL and therefore we would deadlock if we told
               _kill_and_reap_process() to always wait on the child. (Therefore we'll only reap the child if we successfully send
               it a SIGKILL, or if the child already exited by the time we get here.) */
            
            kill_and_reap_process_result = al_wfp_kill_and_reap_process(child_process_id.pid, false),
            child_process_id.valid = false;
            
                AL_ASSERT_OR_PERFORM(kill_and_reap_process_result, AL_NO_OP);
        
        }
        
        al_descriptor_cleanup(&exec_pipe[0], AL_NO_OP);
        al_descriptor_cleanup(&exec_pipe[1], AL_NO_OP);
    
    }
    
    return result;

}

static bool al_sp_wait_for_process_termination(pid_t pid, double timeout, bool *out_process_terminated, int *out_process_status)
{

    al_wfp_result_t wait_for_process_termination_result = al_wfp_result_init;
    int process_status = 0;
    bool process_terminated = false,
         result = false;
    
        assert(timeout != 0.0);
        assert(out_process_terminated);
        assert(out_process_status);
    
    wait_for_process_termination_result = al_wfp_wait_for_process_termination(pid, timeout);
    
        /* Verify that al_wfp_wait_for_process() returned an acceptable result. If it returned something weird, then we're failing. */
        
        AL_ASSERT_OR_PERFORM(wait_for_process_termination_result == al_wfp_result_process_terminated ||
            wait_for_process_termination_result == al_wfp_result_timeout_elapsed ||
                wait_for_process_termination_result == al_wfp_result_process_doesnt_exist_error, goto cleanup);
    
    if (wait_for_process_termination_result == al_wfp_result_process_terminated ||
        wait_for_process_termination_result == al_wfp_result_process_doesnt_exist_error)
    {
    
        bool wait_for_process_status_result = false;
        
        /* We're not using WNOHANG; see al_wait_for_process.h. */
        
        wait_for_process_status_result = al_wfp_wait_for_process_status(pid, 0, &process_status);
        
            AL_ASSERT_OR_PERFORM(wait_for_process_status_result, goto cleanup);
        
        process_terminated = true;
    
    }
    
    result = true;
    
    cleanup:
    {
    
        if (result)
        {
        
            *out_process_terminated = process_terminated;
            *out_process_status = process_status;
        
        }
    
    }
    
    return result;

}

static al_descriptor_t al_sp_safe_dup(int descriptor)
{

    /* This function dup()s the given descriptor, but it ensures that the resulting descriptor is > STDERR_FILENO. This is necessary so
       that we can dup2() the resulting descriptor into one of the 3 default-descriptor slots without the risk of clobbering ourself. */
    
    al_descriptor_t result = al_descriptor_init;
    int dup_descriptor = 0,
        close_result = 0;
    
    dup_descriptor = dup(descriptor);
    
    if (dup_descriptor > STDERR_FILENO)
        result = al_descriptor_create(true, dup_descriptor);
    
    else
    {
    
        result = al_sp_safe_dup(dup_descriptor);
        
        close_result = close(dup_descriptor);
        
        if (close_result && result.valid)
            close(result.descriptor),
            result.valid = false;
    
    }
    
    return result;

}