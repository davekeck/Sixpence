#pragma once
#include <stdbool.h>
#include <fcntl.h>

/* Type Definitions */

enum
{

    al_mdf_operation_set,
    
    al_mdf_operation_enable,
    al_mdf_operation_disable,
    
    _al_mdf_operation_length,
    _al_mdf_operation_first = al_mdf_operation_set

}; typedef int al_mdf_operation;

enum
{

    /* Use ...fl when setting O_NONBLOCK, O_APPEND, etc. */
    
    al_mdf_fcntl_command_fl,
    
    /* Use ...fd when setting FD_CLOEXEC (and nothing else, currently.) */
    
    al_mdf_fcntl_command_fd,
    
    _al_mdf_fcntl_command_length,
    _al_mdf_fcntl_command_first = al_mdf_fcntl_command_fl

}; typedef int al_mdf_fcntl_command;

/* Function Interfaces */

/* This is a simple convenience macro to enable/disable the closed-on-exec flag. */

#define al_mdf_set_descriptor_close_on_exec(descriptor, flag) al_mdf_modify_descriptor_flags((descriptor), ((flag) ? al_mdf_operation_enable :      \
    al_mdf_operation_disable), al_mdf_fcntl_command_fd, FD_CLOEXEC, NULL)

#define al_mdf_set_descriptor_non_blocking(descriptor, flag) al_mdf_modify_descriptor_flags((descriptor), ((flag) ? al_mdf_operation_enable :      \
    al_mdf_operation_disable), al_mdf_fcntl_command_fl, O_NONBLOCK, NULL)

bool al_mdf_modify_descriptor_flags(int descriptor, al_mdf_operation operation, al_mdf_fcntl_command fcntl_command, int change_flags, int *out_original_flags);