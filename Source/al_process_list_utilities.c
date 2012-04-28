#include "al_process_list_utilities.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <stdarg.h>
#include <signal.h>
#include <libgen.h>
#include <assert.h>

#pragma mark Functions Implementations
#pragma mark -

struct kinfo_proc *al_plu_create_processes(size_t *out_processes_count)
{

    int sysctl_options[3],
        sysctl_result = 0;
    size_t processes_count = 0,
           processes_length = 0;
    struct kinfo_proc *processes = NULL,
                      *result = NULL;
    
    /* First, ask how many processes are running for the entire system, so we can create an appropriately-sized
       array to contain the kinfo_procs. */
    
    AL_FILL_STATIC_ARRAY(sysctl_options, CTL_KERN, KERN_PROC, KERN_PROC_ALL);
    
    sysctl_result = sysctl(sysctl_options, 3, NULL, &processes_length, NULL, 0);
    
        AL_ASSERT_OR_PERFORM(!sysctl_result, goto cleanup);
    
    /* Allocate the buffer to hold our kinfo_procs. */
    
    processes = malloc(AL_CAP_MIN(processes_length, 1));
    
        AL_ASSERT_OR_PERFORM(processes, goto cleanup);
    
    if (processes_length)
    {
    
        /* Retrieve the kinfo_procs and put them in 'processes.' */
        
        AL_FILL_STATIC_ARRAY(sysctl_options, CTL_KERN, KERN_PROC, KERN_PROC_ALL);
        
        sysctl_result = sysctl(sysctl_options, 3, processes, &processes_length, NULL, 0);
        
            AL_ASSERT_OR_PERFORM(!sysctl_result, goto cleanup);
        
        processes_count = (processes_length / sizeof(*processes));
    
    }
    
    result = processes;
    
    cleanup:
    {
    
        if (!result)
        {
        
            if (processes)
                free(processes),
                processes = NULL;
        
        }
        
        /* Fill our output variables. */
        
        if (result)
        {
        
            if (out_processes_count)
                *out_processes_count = processes_count;
        
        }
    
    }
    
    return result;

}

bool al_plu_process_id_exists(pid_t process_id)
{

    int kill_result = 0;
    
    errno = 0;
    kill_result = kill(process_id, 0);
    
    return (!kill_result || errno != ESRCH);

}

char *al_plu_short_process_name_for_process_id(pid_t process_id)
{

    int sysctl_options[4],
        sysctl_result = 0;
    struct kinfo_proc process;
    size_t process_length = 0,
           result_length = 0;
    char *result = NULL;
    
    AL_FILL_STATIC_ARRAY(sysctl_options, CTL_KERN, KERN_PROC, KERN_PROC_PID, process_id);
    process_length = sizeof(process);
    
    sysctl_result = sysctl(sysctl_options, 4, &process, &process_length, NULL, 0);
    
        AL_ASSERT_OR_PERFORM(!sysctl_result, goto cleanup);
    
    result_length = strlen(process.kp_proc.p_comm);
    result = malloc(result_length + 1);
    
        AL_ASSERT_OR_PERFORM(result, goto cleanup);
    
    strncpy(result, process.kp_proc.p_comm, result_length + 1);
    
    cleanup:
    {
    }
    
    return result;

}

char *al_plu_full_process_name_for_process_id(pid_t process_id, bool fall_back)
{

    int sysctl_options[3],
        sysctl_result = 0,
        process_arguments_length = 0;
    size_t argument_size = 0,
           basename_length = 0;
    char *process_arguments = NULL,
         *basename_result = NULL,
         *result = NULL;
    
    AL_FILL_STATIC_ARRAY(sysctl_options, CTL_KERN, KERN_ARGMAX, 0);
    argument_size = sizeof(process_arguments_length);
    
    sysctl_result = sysctl(sysctl_options, 2, &process_arguments_length, &argument_size, NULL, 0);
    
        AL_ASSERT_OR_PERFORM(!sysctl_result, goto cleanup);
    
    process_arguments = malloc(process_arguments_length);
    
        AL_ASSERT_OR_PERFORM(process_arguments, goto cleanup);
    
    AL_FILL_STATIC_ARRAY(sysctl_options, CTL_KERN, KERN_PROCARGS, process_id);
    argument_size = process_arguments_length;
    
    sysctl_result = sysctl(sysctl_options, 3, process_arguments, &argument_size, NULL, 0);
    
    if (!sysctl_result)
    {
    
        basename_result = basename(process_arguments);
        
            AL_ASSERT_OR_PERFORM(basename_result, goto cleanup);
        
        basename_length = strlen(basename_result);
        result = malloc(basename_length + 1);
        
            AL_ASSERT_OR_PERFORM(result, goto cleanup);
        
        strncpy(result, basename_result, basename_length + 1);
    
    }
    
    else if (fall_back)
    {
    
        result = al_plu_short_process_name_for_process_id(process_id);
        
            AL_ASSERT_OR_PERFORM(result, goto cleanup);
    
    }
    
    cleanup:
    {
    
        if (process_arguments)
            free(process_arguments),
            process_arguments = NULL;
    
    }
    
    return result;

}

//struct kinfo_proc *al_plu_create_filtered_processes_by_running(const struct kinfo_proc *processes, unsigned int processes_count,
//    unsigned int *out_processes_count)
//{
//
//    unsigned int number_of_filtered_processes = 0,
//                 i = 0;
//    struct kinfo_proc *filtered_processes = NULL,
//                      *result = NULL;
//    
//        assert(processes);
//    
//    filtered_processes = malloc(1);
//    
//        AL_ASSERT_OR_PERFORM(filtered_processes, goto cleanup);
//    
//    for (number_of_filtered_processes = 0, i = 0; i < processes_count; i++)
//    {
//    
//        bool pid_exists = false;
//        
//        pid_exists = al_plu_pid_exists(processes[i].kp_proc.p_pid);
//        
//        if (pid_exists)
//        {
//        
//            filtered_processes = reallocf(filtered_processes, ((number_of_filtered_processes + 1) * sizeof(*filtered_processes)));
//            
//                AL_ASSERT_OR_PERFORM(filtered_processes, goto cleanup);
//            
//            filtered_processes[number_of_filtered_processes] = processes[i];
//            number_of_filtered_processes++;
//        
//        }
//    
//    }
//    
//    result = filtered_processes;
//    
//    cleanup:
//    {
//    
//        if (!result)
//        {
//        
//            if (filtered_processes)
//                free(filtered_processes),
//                filtered_processes = NULL;
//        
//        }
//    
//    }
//    
//    /* Fill our output variables. */
//    
//    if (result)
//    {
//    
//        if (out_processes_count)
//            *out_processes_count = number_of_filtered_processes;
//    
//    }
//    
//    return result;
//
//}
//
//struct kinfo_proc *al_plu_create_filtered_processes_by_uid(const struct kinfo_proc *processes, unsigned int processes_count, uid_t *uids,
//    unsigned int number_of_uids, unsigned int *out_processes_count)
//{
//
//    unsigned int number_of_filtered_processes = 0,
//                 i = 0;
//    struct kinfo_proc *filtered_processes = NULL,
//                      *result = NULL;
//    
//        assert(processes);
//    
//    filtered_processes = malloc(1);
//    
//        AL_ASSERT_OR_PERFORM(filtered_processes, goto cleanup);
//    
//    for (number_of_filtered_processes = 0, i = 0; i < processes_count; i++)
//    {
//    
//        unsigned int ii = 0;
//        
//        for (ii = 0; ii < number_of_uids; ii++)
//        {
//        
//            if (processes[i].kp_eproc.e_pcred.p_ruid == uids[ii])
//            {
//            
//                filtered_processes = reallocf(filtered_processes, ((number_of_filtered_processes + 1) * sizeof(*filtered_processes)));
//                
//                    AL_ASSERT_OR_PERFORM(filtered_processes, goto cleanup);
//                
//                filtered_processes[number_of_filtered_processes] = processes[i];
//                number_of_filtered_processes++;
//                
//                break;
//            
//            }
//        
//        }
//    
//    }
//    
//    result = filtered_processes;
//    
//    cleanup:
//    {
//    
//        if (!result)
//        {
//        
//            if (filtered_processes)
//                free(filtered_processes),
//                filtered_processes = NULL;
//        
//        }
//        
//        /* Fill our output variables. */
//        
//        if (result)
//        {
//        
//            if (out_processes_count)
//                *out_processes_count = number_of_filtered_processes;
//        
//        }
//    
//    }
//    
//    return result;
//
//}
//
//struct kinfo_proc *al_plu_create_filtered_processes_by_name(const struct kinfo_proc *processes, unsigned int processes_count, const char *const *process_names,
//    unsigned int number_of_process_names, bool exact_match, bool sort, unsigned int *out_processes_count)
//{
//
//    al_plu_compare_processes_by_name_context context;
//    unsigned int number_of_filtered_processes = 0,
//                 i = 0;
//    struct kinfo_proc *filtered_processes = NULL,
//                      *result = NULL;
//    
//        assert(processes);
//    
//    filtered_processes = malloc(1);
//    
//        AL_ASSERT_OR_PERFORM(filtered_processes, goto cleanup);
//    
//    /* Prepare our context to pass to our sorting function,  */
//    
//    context.process_names = process_names;
//    context.number_of_process_names = number_of_process_names;
//    context.exact_match = exact_match;
//    
//    for (number_of_filtered_processes = 0, i = 0; i < processes_count; i++)
//    {
//    
//        bool process_matches = false;
//        
//        /* Check if the current process matches any of the specified process names. */
//        
//        process_matches = (bool)al_plu_compare_processes_by_name(&context, &processes[i], NULL);
//        
//        if (process_matches)
//        {
//        
//            filtered_processes = reallocf(filtered_processes, ((number_of_filtered_processes + 1) * sizeof(*filtered_processes)));
//            
//                AL_ASSERT_OR_PERFORM(filtered_processes, goto cleanup);
//            
//            filtered_processes[number_of_filtered_processes] = processes[i];
//            number_of_filtered_processes++;
//        
//        }
//    
//    }
//    
//    if (sort)
//        qsort_r(filtered_processes, number_of_filtered_processes, sizeof(*filtered_processes), &context, al_plu_compare_processes_by_name);
//    
//    result = filtered_processes;
//    
//    cleanup:
//    {
//    
//        if (!result)
//        {
//        
//            if (filtered_processes)
//                free(filtered_processes),
//                filtered_processes = NULL;
//        
//        }
//        
//        /* Fill our output variables. */
//        
//        if (result)
//        {
//        
//            if (out_processes_count)
//                *out_processes_count = number_of_filtered_processes;
//        
//        }
//    
//    }
//    
//    return result;
//
//}
//
//#pragma mark -
//#pragma mark Private Functions Implementations
//#pragma mark -
//
//static int al_plu_compare_processes_by_name(void *context, const void *item_1, const void *item_2)
//{
//
//    al_plu_compare_processes_by_name_context *typed_context = NULL;
//    char *process_1_name = NULL,
//         *process_2_name = NULL;
//    unsigned int i = 0;
//    int result = 0;
//    
//        /* Verify our arguments. */
//        
//        assert(context);
//    
//    typed_context = (al_plu_compare_processes_by_name_context *)context;
//    
//    /* Determine the process names. */
//    
//    if (item_1)
//        process_1_name = al_plu_full_process_name_for_pid(((const struct kinfo_proc *)item_1)->kp_proc.p_pid, true);
//    
//    if (item_2)
//        process_2_name = al_plu_full_process_name_for_pid(((const struct kinfo_proc *)item_2)->kp_proc.p_pid, true);
//    
//    for (i = 0; i < typed_context->number_of_process_names; i++)
//    {
//    
//        /* Note that in the two if-statements below, we're checking whether the applicable process pointer is
//           non-null. This is so this function can be used to check for simple containment (by
//           ...filtered_processes_by_name()) so that the strcmp/strstr doesn't have to be duplicated. */
//        
//        if (process_1_name &&
//            ((typed_context->exact_match && !strcmp(process_1_name, typed_context->process_names[i])) ||
//             (!typed_context->exact_match && strstr(process_1_name, typed_context->process_names[i]))))
//        {
//        
//            result = -1;
//            
//            break;
//        
//        }
//        
//        else if (process_2_name &&
//                 ((typed_context->exact_match && !strcmp(process_2_name, typed_context->process_names[i])) ||
//                  (!typed_context->exact_match && strstr(process_2_name, typed_context->process_names[i]))))
//        {
//        
//            result = 1;
//            
//            break;
//        
//        }
//        
//         /* If we hit this point, it means neither of the given processes' names appeared in process_names, which
//            should never happen when this compare function is called from ...filtered_processes_by_name(), because
//            the list of processes that are supplied to this function have already been guaranteed to match the
//            process names (we're just using this function to - surprise - sort them.) */
//    
//    }
//    
//    cleanup:
//    {
//    
//        if (process_1_name)
//            free(process_1_name),
//            process_1_name = NULL;
//        
//        if (process_2_name)
//            free(process_2_name),
//            process_2_name = NULL;
//    
//    }
//    
//    return result;
//
//}