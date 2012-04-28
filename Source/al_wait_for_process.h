#pragma once
#include <sys/types.h>
#include <stdbool.h>

/* Type Definitions */

enum
{

    al_wfp_result_init,
    
    al_wfp_result_process_terminated,
    al_wfp_result_timeout_elapsed,
    
    al_wfp_result_error,
    al_wfp_result_process_doesnt_exist_error

}; typedef int al_wfp_result_t;

/* Functions */

/* This function waits for a process to terminate, before a timeout elapses.
   timeout < 0.0: wait indefinitely. */

al_wfp_result_t al_wfp_wait_for_process_termination(pid_t process_id, double timeout);

/* This function is a simple wrapper around waitpid(). It's useful to call after al_wfp_wait_for_process() has determined that a child process has terminated.
   
   This function returns true on success, and false if an error occurs. If this function returns true, then *out_process_status == the child process' status
   as returned by waitpid(). If this function returns false, *out_process_status is left unchanged.
   
   out_process_status may be NULL.
   
   ### As of 11/22/09: due to a race condition, you must not use WNOHANG for waitpid_options after observing that a child process has exited using
       _wait_for_process_termination(). See:
       
         http://lists.apple.com/archives/darwin-dev/2009/Oct/msg00129.html
         http://lists.apple.com/archives/darwin-dev/2009/Nov/msg00100.html
         http://lists.apple.com/archives/darwin-dev/2009/Nov/msg00104.html */

bool al_wfp_wait_for_process_status(pid_t process_id, int waitpid_options, int *out_process_status);

/* This function sends the given child process a SIGKILL signal, and if that succeeds or if `always_reap` is true, reaps the process.
   
   Note that if the given PID doesn't exist, this function will always attempt to reap the child process, under the assumption that the process already
   exited and is ready to be reaped.
   
   This functions returns whether the child process was successfully reaped. */

bool al_wfp_kill_and_reap_process(pid_t process_id, bool always_reap);