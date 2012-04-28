#import "ALProcess.h"

#import "al_spawn_process.h"
#import "al_wait_for_process.h"

#import "ALEasyVarg.h"

#import "NSRunLoop+GuaranteedRunMode.h"

#pragma mark ALProcess
#pragma mark -

ALStringConst(ALProcess_ProcessTerminatedNotification);

@interface ALProcess ()

- (void)reapWithHandlerThread: (NSThread *)handlerThread;
- (void)handleProcessTermination: (int)newProcessStatus;
- (NSString *)waitForTerminationMode;

@end

@implementation ALProcess

#pragma mark -
#pragma mark Creation
#pragma mark -

- (id)initWithPathAndArguments: (NSString *)firstArgument, ...
{

    NSArray *newPathAndArguments = nil;
    
        NSParameterAssert(firstArgument && [firstArgument length]);
    
    ALEasyVarg_CreateArray(firstArgument, &newPathAndArguments);
    
        ALAssertOrPerform(newPathAndArguments, goto failed);
    
    if (!(self = [self initWithPathAndArgumentsArray: newPathAndArguments]))
        goto failed;
    
    return self;
    
    failed:
    {
    
        [self release];
    
    }
    
    return nil;

}

- (id)initWithPathAndArgumentsArray: (NSArray *)newPathAndArguments
{

        NSParameterAssert(newPathAndArguments && [newPathAndArguments count]);
        NSParameterAssert([[newPathAndArguments objectAtIndex: 0] length]);
    
    if (!(self = [super init]))
        return nil;
    
    mPathAndArguments = [newPathAndArguments retain];
    mEnvironment = [[[NSProcessInfo processInfo] environment] mutableCopy];
    
    if (!mEnvironment)
        mEnvironment = [[NSMutableDictionary alloc] init];
    
    mStdinDescriptor = al_descriptor_create(YES, STDIN_FILENO);
    mStdoutDescriptor = al_descriptor_create(YES, STDOUT_FILENO);
    mStderrDescriptor = al_descriptor_create(YES, STDERR_FILENO);
    mOtherDescriptors = [[NSMutableSet alloc] init];
    
    mUserID = al_uid_init;
    mGroupID = al_gid_init;
    mProcessID = al_pid_init;
    
    return self;

}

- (void)dealloc
{

    [mOtherDescriptors release],
    mOtherDescriptors = nil;
    
    [mEnvironment release],
    mEnvironment = nil;
    
    [mPathAndArguments release],
    mPathAndArguments = nil;
    
    [super dealloc];

}

#pragma mark -
#pragma mark Public Properties
#pragma mark -

@synthesize pathAndArguments = mPathAndArguments;
@synthesize environment = mEnvironment;
@synthesize stdinDescriptor = mStdinDescriptor;
@synthesize stdoutDescriptor = mStdoutDescriptor;
@synthesize stderrDescriptor = mStderrDescriptor;
@synthesize otherDescriptors = mOtherDescriptors;
@synthesize userID = mUserID;
@synthesize groupID = mGroupID;

@dynamic processID;
@synthesize spawned = mSpawned;
@synthesize monitoring = mMonitoring;
@synthesize processStatus = mProcessStatus;
@dynamic running;

- (pid_t)processID
{

        ALAssertOrRaise([self running]);
    
    return mProcessID.pid;

}

- (int)processStatus
{

        ALAssertOrRaise(mSpawned);
        ALAssertOrRaise(![self running]);
    
    return mProcessStatus;

}

- (BOOL)running
{

    return (mSpawned && mProcessID.valid);

}

#pragma mark -
#pragma mark Methods
#pragma mark -

- (BOOL)spawn
{

    static NSString *const kNullDevicePath = @"/dev/null";
    NSUInteger pathAndArgumentStringsCount = 0,
               environmentStringsCount = 0,
               i = 0;
    const char **pathAndArgumentStrings = nil,
               **environmentStrings = nil;
    NSString *currentEnvironmentKey = nil;
    al_descriptor_t nullDescriptor = al_descriptor_init,
                    standardDescriptors[3],
                    *otherDescriptors = nil;
    NSNumber *currentDescriptorNumber = nil;
    al_sp_result_t spawnProcessResult = al_sp_result_init;
    BOOL result = NO;
    
        /* Verify that we haven't already been spawned. (We're one-time-use.) */
        
        ALAssertOrRaise(!mSpawned);
        ALAssertOrRaise(mPathAndArguments && [mPathAndArguments count] > 0);
        ALAssertOrRaise([[mPathAndArguments objectAtIndex: 0] length]);
    
    /* Form our path and arguments string array. */
    
    pathAndArgumentStringsCount = [mPathAndArguments count];
    pathAndArgumentStrings = malloc(sizeof(*pathAndArgumentStrings) * (pathAndArgumentStringsCount + 1));
    
        ALAssertOrPerform(pathAndArgumentStrings, goto cleanup);
    
    for (i = 0; i < pathAndArgumentStringsCount; i++)
        pathAndArgumentStrings[i] = [[mPathAndArguments objectAtIndex: i] GCSafeUTF8String];
    
    pathAndArgumentStrings[pathAndArgumentStringsCount] = nil;
    
    /* Form our environment strings array */
    
    environmentStringsCount = [mEnvironment count];
    environmentStrings = malloc(sizeof(*environmentStrings) * (environmentStringsCount + 1));
    
        ALAssertOrPerform(environmentStrings, goto cleanup);
    
    i = 0;
    for (currentEnvironmentKey in mEnvironment)
    {
    
        environmentStrings[i] = [[NSString stringWithFormat: @"%@=%@", currentEnvironmentKey, [mEnvironment objectForKey: currentEnvironmentKey]] GCSafeUTF8String];
        i++;
    
    }
    
    environmentStrings[environmentStringsCount] = nil;
    
    /* Create the descriptor that will be substituted for any non-valid descriptors in our standard descriptor array. */
    
    nullDescriptor.descriptor = open([kNullDevicePath GCSafeUTF8String], O_RDWR),
    nullDescriptor.valid = (nullDescriptor.descriptor != -1);
    
        ALAssertOrPerform(nullDescriptor.valid, goto cleanup);
    
    /* Prepare our standard descriptors. */
    
    standardDescriptors[0] = (mStdinDescriptor.valid ? mStdinDescriptor : nullDescriptor);
    standardDescriptors[1] = (mStdoutDescriptor.valid ? mStdoutDescriptor : nullDescriptor);
    standardDescriptors[2] = (mStderrDescriptor.valid ? mStderrDescriptor : nullDescriptor);
    
    otherDescriptors = malloc(sizeof(*otherDescriptors) * ([mOtherDescriptors count] + 1));
    
        ALAssertOrPerform(otherDescriptors, goto cleanup);
    
	i = 0;
    for (currentDescriptorNumber in mOtherDescriptors)
    {
    
            ALAssertOrRaise([currentDescriptorNumber isKindOfClass: [NSNumber class]]);
        
        otherDescriptors[i] = al_descriptor_create(YES, [currentDescriptorNumber intValue]);
        i++;
    
    }
    
    otherDescriptors[[mOtherDescriptors count]] = al_descriptor_init;
    
    /* Spawn the process! */
    
    spawnProcessResult = al_sp_spawn_process(pathAndArgumentStrings, environmentStrings, standardDescriptors, otherDescriptors,
        mUserID, mGroupID, 0.0, &mProcessID.pid, nil);
    
        ALAssertOrPerform(spawnProcessResult == al_sp_result_process_spawned, goto cleanup);
    
    /* PNR */
    
    mSpawned = YES;
    mProcessID.valid = YES;
    [self superRetain];
    result = YES;
    
    cleanup:
    {
    
        al_descriptor_cleanup(&nullDescriptor, ALNoOp);
        
        free(pathAndArgumentStrings),
        pathAndArgumentStrings = nil;
        
        free(otherDescriptors),
        otherDescriptors = nil;
    
    }
    
    return result;

}

- (void)startMonitoring
{

    NSThread *initialThread = nil;
    
        ALAssertOrRaise([self running]);
        ALAssertOrRaise(!mMonitoring);
    
    mMonitoring = YES;
    initialThread = [NSThread currentThread];
    
    mMonitorSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC, mProcessID.pid, DISPATCH_PROC_EXIT,
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    
    if (mMonitorSource)
    {
    
        dispatch_source_set_event_handler(mMonitorSource, ^{ [self reapWithHandlerThread: initialThread]; });
        dispatch_resume(mMonitorSource);
    
    }
    
    /* If we fail to create mMonitorSource, then we'll assume it's because the PID no longer exists, and so we'll
       simply call -reapWithHandlerThread: immediately. */
    
    else
        [self reapWithHandlerThread: initialThread];

}

- (ALProcess_WaitForTerminationResult_t)waitForTerminationWithTimeout: (NSTimeInterval)timeout
{

        ALAssertOrRaise([self running]);
    
    if (mMonitoring)
    {
    
        double startTime = 0.0;
        
        startTime = al_time_current_time();
        
        for (;;)
        {
        
            /* Note that we're assuming that -guaranteedRunMode: could potentially return for reasons other than our call
               to CFRunLoopStop() (in -handleProcessTermination:) or the timeout elapsing. We make this assumption
               because NSObject's -performSelector:onThread: could muck with our run loop and perhaps cause it to exit
               prematurely. Thus, we have this loop to wait until we've explicitly determined that the process has either
               exited or the timeout's elapsed. */
            
            [[NSRunLoop currentRunLoop] guaranteedRunMode: [self waitForTerminationMode]
                timeout: (timeout >= 0.0 ? al_time_remaining_timeout(startTime, timeout) : INFINITY)
                returnAfterSourceHandled: NO];
            
            if (!mProcessID.valid)
                return ALProcess_WaitForTerminationResult_Terminated;
            
            else if (al_time_timeout_has_elapsed(startTime, timeout))
                return ALProcess_WaitForTerminationResult_TimeoutElapsed;
        
        }
    
    }
    
    else
    {
    
        al_wfp_result_t waitForProcessTerminationResult = al_wfp_result_init;
        
        /* Wait for the PID to exit. */
        
        waitForProcessTerminationResult = al_wfp_wait_for_process_termination(mProcessID.pid, timeout);
        
            ALAssertOrRaise(waitForProcessTerminationResult == al_wfp_result_process_terminated ||
                            waitForProcessTerminationResult == al_wfp_result_timeout_elapsed ||
                            waitForProcessTerminationResult == al_wfp_result_process_doesnt_exist_error);
        
        if (waitForProcessTerminationResult == al_wfp_result_process_terminated || waitForProcessTerminationResult == al_wfp_result_process_doesnt_exist_error)
        {
        
            /* Only if the process status is available are we going call waitpid(). */
            
            [self reapWithHandlerThread: nil];
            return ALProcess_WaitForTerminationResult_Terminated;
        
        }
        
        else if (waitForProcessTerminationResult == al_wfp_result_timeout_elapsed)
            return ALProcess_WaitForTerminationResult_TimeoutElapsed;
    
    }
    
    /* Unreachable. */
    
    return ALProcess_WaitForTerminationResult_Init;

}

- (BOOL)terminate
{

        ALAssertOrRaise([self running]);
    
    return (!kill(mProcessID.pid, SIGTERM));

}

- (BOOL)forceTerminate
{

        ALAssertOrRaise([self running]);
    
    return (!kill(mProcessID.pid, SIGKILL));

}

#pragma mark -
#pragma mark Private Methods
#pragma mark -

- (void)reapWithHandlerThread: (NSThread *)handlerThread
{

    int newProcessStatus = 0;
    BOOL waitForProcessStatusResult = NO;
    
        ALAssertOrRaise([self running]);
    
    waitForProcessStatusResult = al_wfp_wait_for_process_status(mProcessID.pid, 0, &newProcessStatus);
    
        ALAssertOrRaise(waitForProcessStatusResult);
        ALAssertOrRaise(WIFEXITED(newProcessStatus) || WIFSIGNALED(newProcessStatus));
    
    /* If we were given a handler thread, then we'll call -handleProcessTermination: asynchronously on that thread.
       Otherwise we'll simply call -handleProcessTermination: directly. */
    
    if (handlerThread)
        [self asyncPerformSelector: @selector(handleProcessTermination:) onThread: handlerThread
            modes: [NSSet setWithObjects: NSRunLoopCommonModes, [self waitForTerminationMode], nil] arguments: &newProcessStatus];
    
    else
        [self handleProcessTermination: newProcessStatus];

}

- (void)handleProcessTermination: (int)newProcessStatus
{

        NSParameterAssert(WIFEXITED(newProcessStatus) || WIFSIGNALED(newProcessStatus));
        ALAssertOrRaise([self running]);
    
    mProcessStatus = newProcessStatus;
    mProcessID.valid = NO;
    
    /* Cleanup after -startMonitoring */
    
    if (mMonitorSource)
    {
    
        dispatch_source_cancel(mMonitorSource);
        
        dispatch_release(mMonitorSource),
        mMonitorSource = nil;
    
    }
    
    /* Let everyone know that we've terminated. */
    
    [[NSNotificationCenter defaultCenter] postNotificationName: ALProcess_ProcessTerminatedNotification object: self userInfo: nil];
    
    /* If this method is being called from within the -waitForTerminationWithTimeout: stack frame, then the current run loop mode will
       be -waitForTerminationMode. If that's the case, we need to stop the run loop. */
    
    if ([[[NSRunLoop currentRunLoop] currentMode] isEqualToString: [self waitForTerminationMode]])
        CFRunLoopStop(CFRunLoopGetCurrent());
    
    /* Balance the retain in -spawn. */
    
    [self superRelease];

}

- (NSString *)waitForTerminationMode
{

    return ALUniqueStringForThisMethodAndInstance;

}

@end