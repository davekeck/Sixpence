#pragma once

/* Type Definitions */

enum
{

    al_wfd_event_type_init, 
    
    al_wfd_event_type_read,
    al_wfd_event_type_write,
    al_wfd_event_type_error,
    
    _al_wfd_event_type_length,
    _al_wfd_event_type_first = al_wfd_event_type_read,

}; typedef int al_wfd_event_type_t;

enum
{

    al_wfd_result_init,
    
    al_wfd_result_event_occurred,
    al_wfd_result_timeout_elapsed,
    
    al_wfd_result_error

}; typedef int al_wfd_result_t;

/* Constants */

extern const double al_wfd_maximum_timeout;

/* Function Interfaces */

/* This function is a simple wrapper around select(). timeout < 0.0: wait indefinitely; timeout == 0.0: poll;
   timeout > 0.0: normal timeout. */
/* Due to limits on select()/pselect(), the given timeout argument must not exceed al_wfd_maximum_timeout,
   which is on the magnitude of years. */

al_wfd_result_t al_wfd_wait_for_descriptor(int descriptor, al_wfd_event_type_t event_type, double timeout);