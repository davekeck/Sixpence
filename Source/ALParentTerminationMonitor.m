#import "ALParentTerminationMonitor.h"

#pragma mark Class Implementations
#pragma mark -

@implementation ALParentTerminationMonitor

#pragma mark Methods
#pragma mark -

- (void)monitorParentTerminationWithQueue: (dispatch_queue_t)queue block: (dispatch_block_t)block
{

    pid_t parentPID = 0,
          parentPID2 = 0;
    dispatch_source_t monitorSource = nil;
    NSConditionLock *eventHandlerLock = nil;
    dispatch_block_t eventHandlerBlock = nil;
    
        NSParameterAssert(queue);
        NSParameterAssert(block);
    
    /* Get the parent's PID; if the parent's PID == 1, then we're assuming the parent already exited so we'll invoke our handler on the global queue
       and return. */
    
    parentPID = getppid();
    
        ALConfirmOrPerform(parentPID != 1, dispatch_async(queue, block); return);
    
    monitorSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC, parentPID, DISPATCH_PROC_EXIT, queue);
    
        /* If we failed to create monitorSource, then we'll assume it's because the parent already exited, so we'll invoke our handler block and return. */
        
        ALConfirmOrPerform(monitorSource, dispatch_async(queue, block); return);
    
    eventHandlerLock = [[[NSConditionLock alloc] initWithCondition: NO] autorelease];
    
    eventHandlerBlock =
    ^{
    
        BOOL perform = NO;
        
        /* We're using a condition lock here to protect ourself from being executed more than once, since this block is also dispatched manually
           (rather than by monitorSource) if we notice that we attached the source to the wrong PID. See below.
           
           Note also that we're using a lock _object_ rather than a dispatch_once_t or similar scalar so that the lock is automatically
           retain-counted and kept alive by the block. (There doesn't appear to be an easy way to associate malloc'd memory (which is what the
           dispatch_once_t would be) with a block, to be automatically freed when the block is deallocated.) */
        
        [eventHandlerLock lock];
        perform = (![eventHandlerLock condition]);
        [eventHandlerLock unlockWithCondition: YES];
        
        /* If this is the first time the block has been executed, then we'll perform our actions! */
        
        if (perform)
        {
        
            block();
            
            dispatch_source_cancel(monitorSource);
            dispatch_release(monitorSource);
        
        }
    
    };
    
    dispatch_source_set_event_handler(monitorSource, eventHandlerBlock);
    dispatch_resume(monitorSource);
    
    /* This second check is necessary due to a race condition where another process could have spawned after the original getppid(), with
       the same PID as the old parent. If this happened, our source would not be waiting on the parent to exit, but rather an unrelated
       process. But due to the order of events in the kernel, a process (the old parent) cannot be reaped until all its children have
       been reparented by launchd. That is, the old parent's PID cannot be reused until the children of the parent are able to observe
       that getppid() == 1. Therefore after we've configured the source, if getppid() still returns the original value, then the source
       was setup with the correct process. Furthermore, we know that the _EXIT kevent hasn't been dispatched yet, since it occurs after
       the launchd-reparenting.
       
       See http://lists.apple.com/archives/cocoa-dev/2010/Apr/msg00102.html */
    
    parentPID2 = getppid();
    
        ALConfirmOrPerform(parentPID == parentPID2, dispatch_async(queue, eventHandlerBlock); return);

}

@end