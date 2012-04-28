#import <Foundation/Foundation.h>

extern NSString *const ALProcess_ProcessTerminatedNotification;

enum
{

    ALProcess_WaitForTerminationResult_Init,
    
    ALProcess_WaitForTerminationResult_Terminated,
    ALProcess_WaitForTerminationResult_TimeoutElapsed

}; typedef NSUInteger ALProcess_WaitForTerminationResult_t;

@interface ALProcess : NSObject
{

@private
    
    NSArray *mPathAndArguments;
    NSMutableDictionary *mEnvironment;
    al_descriptor_t mStdinDescriptor;
    al_descriptor_t mStdoutDescriptor;
    al_descriptor_t mStderrDescriptor;
    NSMutableSet *mOtherDescriptors;
    al_uid_t mUserID;
    al_gid_t mGroupID;
    
    /* After-spawn variables */
    
    al_pid_t mProcessID;
    BOOL mSpawned;
    BOOL mMonitoring;
    dispatch_source_t mMonitorSource;
    int mProcessStatus;

}

/* Creation */

- (id)initWithPathAndArguments: (NSString *)firstArgument, ... NS_REQUIRES_NIL_TERMINATION;
- (id)initWithPathAndArgumentsArray: (NSArray *)newPathAndArguments;

/* Properties */

@property(nonatomic, readonly, retain) NSArray *pathAndArguments;
@property(nonatomic, readonly, retain) NSMutableDictionary *environment;

/* By default, the child process inherits the parent's three standard descriptors. If any of the std...Descriptor properties are assigned
   al_descriptor_init, then the respective descriptor will be routed to /dev/null in the child process.
   
   All other descriptors in the parent process will automatically be closed in the child process, unless they're included in
   otherDescriptors, which is a set of NSNumbers. */

@property(nonatomic) al_descriptor_t stdinDescriptor;
@property(nonatomic) al_descriptor_t stdoutDescriptor;
@property(nonatomic) al_descriptor_t stderrDescriptor;
@property(nonatomic, readonly) NSMutableSet *otherDescriptors;
@property(nonatomic) al_uid_t userID;
@property(nonatomic) al_gid_t groupID;

@property(nonatomic, readonly) pid_t processID;
@property(nonatomic, readonly) BOOL spawned;
@property(nonatomic, readonly) BOOL monitoring;
@property(nonatomic, readonly) int processStatus;
@property(nonatomic, readonly) BOOL running;

/* Methods */
/* If you don't call -startMonitoring, you must call -waitForTerminationWithTimeout: until it returns _Terminated for the child to be
   reaped, and for the ALProcess instance to be deallocated. */

- (BOOL)spawn;
- (void)startMonitoring;

/* This method posts the _ProcessDidTerminateNotification notification from within its stack frame if the process exits. */

- (ALProcess_WaitForTerminationResult_t)waitForTerminationWithTimeout: (NSTimeInterval)timeout;

/* These raise if the receiver hasn't been spawned, or if we've already observed that it exited.
   They return whether the kill() syscall returns 0. */

- (BOOL)terminate;
- (BOOL)forceTerminate;

@end