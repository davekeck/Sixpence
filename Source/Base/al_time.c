#include "al_time.h"

#include <stdbool.h>
#include <stdint.h>
#include <unistd.h>
#include <math.h>
#include <assert.h>
#include <limits.h>
#include <errno.h>
#include <stdio.h>
#include <time.h>
#include <mach/mach_time.h>
#include <dispatch/dispatch.h>

#pragma mark Definitions
#pragma mark -

#define AL_TIME_CONVERT_TIME_TO_TIME_STRUCT(time, seconds_member_name, seconds_fraction_member_name, number_of_seconds_fraction_per_second, out_time_struct)      \
({                                                                                                                                                                \
                                                                                                                                                                  \
        assert(out_time_struct);                                                                                                                                  \
                                                                                                                                                                  \
    (out_time_struct)->seconds_member_name = (__typeof__((out_time_struct)->seconds_member_name))(time);                                                          \
                                                                                                                                                                  \
    (out_time_struct)->seconds_fraction_member_name = (__typeof__((out_time_struct)->seconds_fraction_member_name))(((double)(time) -                             \
        (double)(out_time_struct)->seconds_member_name) * (double)(number_of_seconds_fraction_per_second));                                                       \
                                                                                                                                                                  \
})

#define AL_TIME_CONVERT_TIME_STRUCT_TO_TIME(time_struct, seconds_member_name, seconds_fraction_member_name, number_of_seconds_fraction_per_second, out_time)      \
({                                                                                                                                                                \
                                                                                                                                                                  \
        assert(out_time);                                                                                                                                         \
                                                                                                                                                                  \
    *(out_time) = ((double)(time_struct).seconds_member_name + ((double)(time_struct).seconds_fraction_member_name /                                              \
        (double)(number_of_seconds_fraction_per_second)));                                                                                                        \
                                                                                                                                                                  \
})

#pragma mark -
#pragma mark Constants
#pragma mark -

const double al_time_unknown_time = AL_TIME_UNKNOWN_TIME;

#pragma mark Function Implementations
#pragma mark -

double al_time_current_time(void)
{

    static dispatch_once_t init_once = 0;
    static mach_timebase_info_data_t timebase_info;
    
    dispatch_once(&init_once,
    ^{
    
        mach_timebase_info((mach_timebase_info_data_t *)&timebase_info);
    
    });
    
    return ((double)((mach_absolute_time() * (uint64_t)timebase_info.numer) / (uint64_t)timebase_info.denom) / (double)NSEC_PER_SEC);

}

double al_time_elapsed_time(double start_time)
{

    return (al_time_current_time() - start_time);

}

void al_time_guaranteed_sleep(double timeout)
{

    double start_time = 0.0;
    
    start_time = al_time_current_time();
    
    for (;;)
    {
    
        struct timespec timespec;
        int nanosleep_result = 0;
        
        if (timeout >= 0.0)
            timespec = al_time_convert_time_to_timespec(al_time_remaining_timeout(start_time, timeout));
        
        else
        {
        
            timespec.tv_sec = LONG_MAX;
            timespec.tv_nsec = 0;
        
        }
        
        errno = 0;
        nanosleep_result = nanosleep(&timespec, NULL);
        
            /* If nanosleep fails for reasons other than EINTR, we're considering it programmer error. */
            
            AL_ASSERT_OR_ABORT(!nanosleep_result || (nanosleep_result == -1 && errno == EINTR));
        
        if (timeout >= 0.0 && !nanosleep_result)
            break;
    
    }

}

double al_time_remaining_time_interval(double start_time, double time_interval)
{

    return (time_interval - al_time_elapsed_time(start_time));

}

bool al_time_time_interval_has_elapsed(double start_time, double time_interval)
{

    return (al_time_elapsed_time(start_time) >= time_interval);

}

double al_time_remaining_timeout(double start_time, double timeout)
{

        if (timeout < 0.0)
            return -1.0;
        
        if (timeout == 0.0)
            return 0.0;
    
    return AL_CAP_MIN(timeout - al_time_elapsed_time(start_time), 0.0);

}

bool al_time_timeout_has_elapsed(double start_time, double timeout)
{

        if (timeout < 0.0)
            return false;
        
        if (timeout == 0.0)
            return true;
    
    return (al_time_elapsed_time(start_time) >= timeout);

}

struct timeval al_time_convert_time_to_timeval(double time_value)
{

    struct timeval result;
    
    AL_TIME_CONVERT_TIME_TO_TIME_STRUCT(time_value, tv_sec, tv_usec, USEC_PER_SEC, &result);
    
    return result;

}

double al_time_convert_timeval_to_time(struct timeval timeval)
{

     double result = 0.0;
     
     AL_TIME_CONVERT_TIME_STRUCT_TO_TIME(timeval, tv_sec, tv_usec, USEC_PER_SEC, &result);
     
     return result;

}

struct timespec al_time_convert_time_to_timespec(double time_value)
{

    struct timespec result;
    
    AL_TIME_CONVERT_TIME_TO_TIME_STRUCT(time_value, tv_sec, tv_nsec, NSEC_PER_SEC, &result);
    
    return result;

}

double al_time_convert_timespec_to_time(struct timespec timespec)
{

    double result = 0.0;
    
    AL_TIME_CONVERT_TIME_STRUCT_TO_TIME(timespec, tv_sec, tv_nsec, NSEC_PER_SEC, &result);
    
    return result;

}

mach_timespec_t al_time_convert_time_to_mach_timespec(double time_value)
{

    mach_timespec_t result;
    
    AL_TIME_CONVERT_TIME_TO_TIME_STRUCT(time_value, tv_sec, tv_nsec, NSEC_PER_SEC, &result);
    
    return result;

}

double al_time_convert_mach_timespec_to_time(mach_timespec_t mach_timespec)
{

    double result = 0.0;
    
    AL_TIME_CONVERT_TIME_STRUCT_TO_TIME(mach_timespec, tv_sec, tv_nsec, NSEC_PER_SEC, &result);
    
    return result;

}