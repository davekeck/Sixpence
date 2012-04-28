#pragma once
#include <sys/types.h>
#include <stdbool.h>
#include <stdarg.h>

/* Type Definitions */

enum
{

    al_sp_result_init,
    
    al_sp_result_process_spawned,
    al_sp_result_process_terminated,
    
    al_sp_result_error,
    al_sp_result_wait_error

}; typedef int al_sp_result_t;

extern const al_descriptor_t al_sp_standard_descriptors_inherit[];
extern const al_descriptor_t al_sp_standard_descriptors_null[];

/* Functions */

/* This is a simple wrapper around _spawn_process() which accepts a convenient argument list. */

al_sp_result_t al_sp_spawn_process_va(const char *const environment[], const al_descriptor_t standard_descriptors[],
    const al_descriptor_t other_descriptors[], al_uid_t user_id, al_gid_t group_id, double timeout, pid_t *out_process_id, int *out_process_status,
    const char *first_argument, ...) __attribute__((sentinel));

/* Spawns a process, with several options. Originally this function was a wrapper around posix_spawn(), but then we added the close-all-descriptors
   functionality (where all file descriptors are closed, except stdin/out/err and those specified in descriptors[].) The reason we could no longer
   use posix_spawn after adding this functionality is because the _addclose() function (which tells posix_spawn to close a file descriptor in the
   new process) causes the posix_spawn to fail if the given descriptor is invalid. If we were to only _addclose() on valid descriptors, we would
   introduce a race between the time that _addclose() was called, and the time that the process actually forked. In between that time, a new
   descriptor could be created on another thread, which the child process would inherit. By using fork()/exec() directly, we can avoid this race
   and guarantee that only the intended descriptors will be inherited by the child process.
   
   Function arguments:
   
       arguments: the list of arguments that the spawned process will receive; the first argument being the path to the executable, and
                  the last argument being NULL.
       
       environment: the environment that the spawned process will assume. Typically this should be 'environ'. Can be NULL.
       
       standard_descriptors: an array of 3 descriptors (which are mapped to stdin, stdout, stderr respectively), or
                             the _inherit constant, which will leave stdin, stdout, and stderr untouched, or 
                             the _null constant, which will map stdin, stdout, and stderr to /dev/null.
       
       other_descriptors: an array of descriptors that should be left open in the child process, inherited from the parent. This array must be
                          delimited by an al_descriptor_init.
                          Can be NULL.
       
       user_id/group_id: if a valid user/group ID is supplied, upon forking, the child process will call setuid/setgid with the UID/GID. See
                         al_uid_t and al_gid_t.
       
       timeout:
            
            If timeout == 0.0, return immediately after the process is spawned.
            If timeout < 0.0, wait indefinitely for the child process to terminate.
            If timeout > 0.0, wait the given timeout for the process to terminate.
       
       out_process_id: if _spawn_process() returns _process_spawned or _wait_error, then *out_process_id contains the PID of the child process.
                       Can be NULL.
       
       out_process_status: if _spawn_process() returns _process_terminated, *out_process_status contains the child process' status as returned by waitpid().
    
    Function results:
    
       _process_spawned: the process was successfully spawned, and its PID is available in *out_process_id. If you supplied a timeout > 0.0,
                         then the process did not terminate before the timeout.
       _process_terminated: the process terminated, and its status (as returned from waitpid()) is available in *out_process_status.
       _error: a generic error occurred. Bad news bears, kid. :'(
       _wait_error: the process was spawned successfully, but an error occurred while waiting for the process to terminate; its PID is
                    available in *out_process_id. This error can only occur when timeout > 0.0.

*/

al_sp_result_t al_sp_spawn_process(const char *const arguments[], const char *const environment[], const al_descriptor_t standard_descriptors[],
    const al_descriptor_t other_descriptors[], al_uid_t user_id, al_gid_t group_id, double timeout, pid_t *out_process_id, int *out_process_status);