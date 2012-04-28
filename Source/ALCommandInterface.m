#import "ALCommandInterface.h"

#import <Sixpence/Sixpence.h>

#pragma mark Class Implementations
#pragma mark -

@implementation ALCommandInterface

#pragma mark -
#pragma mark Methods
#pragma mark -

- (BOOL)performCommandWithOptions: (ALCommandInterface_Options)options stdoutData: (NSData **)outStdoutData pathAndArguments: (NSString *)firstArgument, ...
{

    NSArray *pathAndArgumentsArray = nil;
    ALPipe *readPipe = nil;
    ALProcess *process = nil;
    __block NSData *stdoutData = nil;
    ALProcess_WaitForTerminationResult_t waitForTerminationResult = ALProcess_WaitForTerminationResult_Init;
    int processStatus = 0;
    NSConditionLock *captureStdoutLock = nil;
    __block BOOL captureStdoutResult = NO;
    BOOL captureStdoutStarted = NO,
         spawnResult = NO,
         result = NO;
    
        NSParameterAssert(firstArgument && [firstArgument length]);
        NSParameterAssert(ALEqualBools((options & ALCommandInterface_Options_CaptureStdout), outStdoutData));
    
    /* Create an array from our variable arguments, and create our process from that. */
    
    ALEasyVarg_CreateArray(firstArgument, &pathAndArgumentsArray);
    
        ALAssertOrPerform(pathAndArgumentsArray, goto cleanup);
    
    process = [[[ALProcess alloc] initWithPathAndArgumentsArray: pathAndArgumentsArray] autorelease];
    
    /* Empty environment? */
    
    if (options & ALCommandInterface_Options_EmptyEnvironment)
        [[process environment] removeAllObjects];
    
    /* Execute as root? */
    
    if (options & ALCommandInterface_Options_ExecuteAsRoot)
    {
    
        [process setUserID: al_uid_create(YES, 0)];
        [process setGroupID: al_gid_create(YES, 0)];
    
    }
    
    if (options & ALCommandInterface_Options_NullStandardDescriptors)
    {
    
        [process setStdinDescriptor: al_descriptor_init];
        [process setStdoutDescriptor: al_descriptor_init];
        [process setStderrDescriptor: al_descriptor_init];
    
    }
    
    /* Capture stdout? */
    
    if (options & ALCommandInterface_Options_CaptureStdout)
    {
    
        /* Create our pipe and assign the write end to be the new process' stdout. */
        
        [ALPipe sharedReadPipe: &readPipe closeOnDealloc: YES sharedWritePipe: nil closeOnDealloc: NO];
        [process setStdoutDescriptor: [readPipe writeDescriptor]];
        
        /* Create our condition lock which will act as our 'async block finished' synchronization mechanism. (When condition == YES,
           the block is finished.) */
        
        captureStdoutLock = [[[NSConditionLock alloc] initWithCondition: NO] autorelease];
        
        /* Start our asynchronous block to read data from the pipe as it becomes available. */
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^{
        
            static const size_t kBufferLength = 0x1000;
            void *buffer = nil;
            NSMutableData *bufferData = nil;
            
            buffer = malloc(kBufferLength);
            
                ALAssertOrPerform(buffer, goto cleanup);
            
            /* This isn't autoreleased because we need to hand it off to the initial thread once we're finished. The initial thread will
               assume responsibility for its release. */
            
            bufferData = [[NSMutableData alloc] init];
            
            /* Keep reading and appending data to bufferData until the write end of the pipe is closed (marked by read() returning 0). */
            
            for (;;)
            {
            
                ssize_t readResult = 0;
                
                do
                {
                
                    errno = 0;
                    readResult = read([readPipe readDescriptor].descriptor, buffer, kBufferLength);
                
                } while (readResult == -1 && errno == EINTR);
                
                    ALAssertOrPerform(readResult >= 0, goto cleanup);
                    ALConfirmOrPerform(readResult, break);
                
                [bufferData appendBytes: buffer length: readResult];
            
            }
            
            captureStdoutResult = YES;
            
            cleanup:
            {
            
                free(buffer),
                buffer = nil;
                
                /* Finally, assign our stdoutData and let the initial thread know that we're finished via captureStdoutLock. (Note that
                   stdoutData will be released by the initial thread once it gets ahold of it safely.) */
                
                stdoutData = bufferData;
                [captureStdoutLock lock];
                [captureStdoutLock unlockWithCondition: YES];
            
            }
        
        });
        
        captureStdoutStarted = YES;
    
    }
    
    /* Spawn the process! */
    
    spawnResult = [process spawn];
    
        ALAssertOrPerform(spawnResult, goto cleanup);
    
    /* If we're capturing stdout, close the write end of our pipe now that our process has spawned, so that the read() in our async block
       returns 0 when the child exits, allowing the block to exit. */
    
    if (options & ALCommandInterface_Options_CaptureStdout)
        [ALPipe prepareSharedReadPipeAfterExec: readPipe sharedWritePipe: nil];
    
    /* Wait for the process to exit. */
    
    waitForTerminationResult = [process waitForTerminationWithTimeout: -1.0];
    
        ALAssertOrPerform(waitForTerminationResult == ALProcess_WaitForTerminationResult_Terminated, goto cleanup);
    
    processStatus = [process processStatus];
    
        ALAssertOrPerform(WIFEXITED(processStatus) || WIFSIGNALED(processStatus), goto cleanup);
        
        /* If we were told to consider the process startus, then verify that the process exited due to a call to exit(), and that
           its exit status == 0. */
        
        ALAssertOrPerform(!(options & ALCommandInterface_Options_ConsiderProcessStatus) ||
            ((options & ALCommandInterface_Options_ConsiderProcessStatus) && WIFEXITED(processStatus) && !WEXITSTATUS(processStatus)), goto cleanup);
    
    result = YES;
    
    cleanup:
    {
    
        /* Kill the process if it's still alive. */
        
        if (process && [process running])
        {
        
            [process forceTerminate];
            [process waitForTerminationWithTimeout: -1.0];
        
        }
        
        /* Wait for the stdout-reading async block to finish if it was started. */
        
        if (captureStdoutStarted)
        {
        
            /* We need to make sure the write end of the pipe is closed locally before we wait for the stdout-reading async block
               to exit. If the write end of the pipe were still open locally, the read() call in the async block would never
               return 0, and therefore the block would never exit and we'd deadlock. */
            
            [ALPipe prepareSharedReadPipeAfterExec: readPipe sharedWritePipe: nil];
            
            [captureStdoutLock lockWhenCondition: YES];
            [captureStdoutLock unlock];
            
            /* Release stdoutData, as the async block retained it on our behalf. (Note that we're autoreleasing so that we can
               hand it to our caller safely via *outStdoutData, below.) */
            
            [stdoutData autorelease];
            
                /* If something went wrong in capturing the stdout data, then we're failing. */
                
                ALConfirmOrPerform(captureStdoutResult, result = NO);
        
        }
        
        [ALPipe closeSharedReadPipe: readPipe sharedWritePipe: nil];
        
        /* Finally, supply stdoutData to our caller if we were successful. */
        
        if (result && (options & ALCommandInterface_Options_CaptureStdout) && outStdoutData)
            *outStdoutData = stdoutData;
    
    }
    
    return result;

}

@end