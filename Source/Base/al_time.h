#pragma once
#include <stdbool.h>
#include <mach/clock_types.h>

/* Definitions */

#define AL_TIME_UNKNOWN_TIME INFINITY

/* Constants */

extern const double al_time_unknown_time;

/* Functions */

double al_time_current_time(void);
double al_time_elapsed_time(double start_time);

/* timeout < 0.0 means 'sleep indefinitely'. */

void al_time_guaranteed_sleep(double timeout);

double al_time_remaining_time_interval(double start_time, double time_interval);
bool al_time_time_interval_has_elapsed(double start_time, double time_interval);

/* _remaining_timeout() and _timeout_has_elapsed() are the same as _remaining_time_interval() _time_interval_has_elapsed(),
   except that negative timeouts are assumed to be infinite, and an exactly-0.0 timeout is always guaranteed to have
   elapsed. As such:
   
       al_time_remaining_timeout(st, < 0.0)      == -1.0
       al_time_timeout_has_elapsed(st, < 0.0)    == false
       
       al_time_remaining_timeout(st, 0.0)        == 0.0
       al_time_timeout_has_elapsed(st, 0.0)      == true
   
   Furthermore, _remaining_timeout() will never return a negative number unless the supplied timeout is negative. In all other
   cases, the minimum result is 0.0. */

double al_time_remaining_timeout(double start_time, double timeout);
bool al_time_timeout_has_elapsed(double start_time, double timeout);

struct timeval al_time_convert_time_to_timeval(double time_value);
double al_time_convert_timeval_to_time(struct timeval timeval);

struct timespec al_time_convert_time_to_timespec(double time_value);
double al_time_convert_timespec_to_time(struct timespec timespec);

mach_timespec_t al_time_convert_time_to_mach_timespec(double time_value);
double al_time_convert_mach_timespec_to_time(mach_timespec_t mach_timespec);