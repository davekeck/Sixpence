#include <sys/types.h>
#include <stdbool.h>
#include <dispatch/dispatch.h>

static inline void al_set_dispatch_source_resumed(dispatch_source_t source, bool *in_out_currently_resumed, bool resumed)
{

        assert(source);
        assert(in_out_currently_resumed);
        
        AL_CONFIRM_OR_PERFORM(*in_out_currently_resumed != resumed, return);
    
    *in_out_currently_resumed = resumed;
    
    if (resumed)
        dispatch_resume(source);
    
    else
        dispatch_suspend(source);

}