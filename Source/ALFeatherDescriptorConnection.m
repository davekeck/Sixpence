#import "ALFeatherDescriptorConnection.h"

#import "al_modify_descriptor_flags.h"
#import "al_set_dispatch_source_resumed.h"

#import "NSObject+ResourceManagement.h"

@interface ALFeatherDescriptorConnection ()

/* Properties */

@property(nonatomic, retain) NSConditionLock *stateLock;

@property(nonatomic, assign) al_descriptor_t readDescriptor;
@property(nonatomic, assign) al_descriptor_t writeDescriptor;

@property(nonatomic, assign) dispatch_source_t incomingDataSource;
@property(nonatomic, assign) bool incomingDataSourceResumed;

@property(nonatomic, assign) dispatch_source_t outgoingDataSource;
@property(nonatomic, retain) NSMutableData *outgoingRequestData;
@property(nonatomic, assign) bool outgoingDataSourceResumed;

/* Private Methods */

- (void)handleIncomingData;
- (void)handleOutgoingData;

@end

@implementation ALFeatherDescriptorConnection

#pragma mark -
#pragma mark Properties
#pragma mark -

@synthesize stateLock = mStateLock;

@synthesize readDescriptor = mReadDescriptor;
@synthesize writeDescriptor = mWriteDescriptor;

@synthesize incomingDataSource = mIncomingDataSource;
@synthesize incomingDataSourceResumed = mIncomingDataSourceResumed;

@synthesize outgoingDataSource = mOutgoingDataSource;
@synthesize outgoingRequestData = mOutgoingRequestData;
@synthesize outgoingDataSourceResumed = mOutgoingDataSourceResumed;

#pragma mark -
#pragma mark Creation
#pragma mark -

- (id)initWithReadDescriptor: (int)readDescriptor writeDescriptor: (int)writeDescriptor
    localServerObject: (NSObject *)localServerObject remoteServerProtocol: (Protocol *)remoteServerProtocol
{

    BOOL setNonBlockingResult = NO;
    
        NSParameterAssert(readDescriptor >= 0);
        NSParameterAssert(writeDescriptor >= 0);
    
    if (!(self = [super initWithLocalServerObject: localServerObject remoteServerProtocol: remoteServerProtocol]))
        goto failed;
    
    [self setStateLock: [[[NSConditionLock alloc] initWithCondition: YES] autorelease]];
    
    /* Set up our descriptors */
    
    mReadDescriptor = al_descriptor_create(YES, readDescriptor);
    setNonBlockingResult = al_mdf_set_descriptor_non_blocking(mReadDescriptor.descriptor, YES);
    
        ALAssertOrPerform(setNonBlockingResult, goto failed);
    
    mWriteDescriptor = al_descriptor_create(YES, writeDescriptor);
    setNonBlockingResult = al_mdf_set_descriptor_non_blocking(mWriteDescriptor.descriptor, YES);
    
        ALAssertOrPerform(setNonBlockingResult, goto failed);
    
    /* Set up our incoming-data dispatch source */
    
    mIncomingDataSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, mReadDescriptor.descriptor, 0,
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    
        ALAssertOrPerform(mIncomingDataSource, goto failed);
    
    dispatch_source_set_event_handler(mIncomingDataSource, ^{ [self handleIncomingData]; });
    dispatch_source_set_cancel_handler(mIncomingDataSource, ^{ [self releaseResource: &mReadDescriptor]; });
    al_set_dispatch_source_resumed(mIncomingDataSource, &mIncomingDataSourceResumed, NO);
    
    /* Set up our outgoing-data dispatch source */
    
    mOutgoingDataSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, mWriteDescriptor.descriptor, 0,
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    
        ALAssertOrPerform(mOutgoingDataSource, goto failed);
    
    /* PNR */
    
    dispatch_source_set_event_handler(mOutgoingDataSource, ^{ [self handleOutgoingData]; });
    dispatch_source_set_cancel_handler(mOutgoingDataSource, ^{ [self releaseResource: &mWriteDescriptor]; });
    al_set_dispatch_source_resumed(mOutgoingDataSource, &mOutgoingDataSourceResumed, NO);
    
    /* Create our buffer to which we'll append all of our outgoing data. */
    
    [self setOutgoingRequestData: [NSMutableData data]];
    
    /* Retain our read/write descriptors on behalf of the incoming/outgoing data sources, respectively.
       
       ### Note that this must come after the PNR; otherwise, the receiver will never be deallocated if initialize fails,
           since -retainResource causes the receiver to be retained. */
    
    [self retainResource: &mReadDescriptor];
    [self retainResource: &mWriteDescriptor];
    
    /* Balanced in -invalidate. */
    
    [self superRetain];
    
    /* Now that we're fully set up we can allow our our incoming-data dispatch source to fire and execute on a separate thread. */
    
    al_set_dispatch_source_resumed(mIncomingDataSource, &mIncomingDataSourceResumed, YES);
    return self;
    
    failed:
    {
    
        [self release];
    
    }
    
    return nil;

}

- (void)dealloc
{

    /* -dealloc must be able to handle the receiver being in a partially-initialized state due to -init failing. */
    
    [self setOutgoingRequestData: nil];
    
    if (mOutgoingDataSource)
        dispatch_release(mOutgoingDataSource),
        mOutgoingDataSource = nil;
    
    if (mIncomingDataSource)
        dispatch_release(mIncomingDataSource),
        mIncomingDataSource = nil;
    
    /* Note that we're not cleaning up the read/write descriptors here; they're resources that are cleaned up before -dealloc runs.
       See -cleanupResource:. */
    
    [self setStateLock: nil];
    [super dealloc];

}

- (void)cleanupResource: (void *)resource
{

        NSParameterAssert(resource);
    
    if (resource == &mReadDescriptor)
        al_descriptor_cleanup(&mReadDescriptor, ALNoOp);
    
    else if (resource == &mWriteDescriptor)
        al_descriptor_cleanup(&mWriteDescriptor, ALNoOp);
    
    else
        [super cleanupResource: resource];

}

- (void)invalidate
{

    BOOL invalidate = NO;
    
    [mStateLock lock];
    invalidate = [mStateLock condition];
    [mStateLock unlockWithCondition: NO];
    
    if (invalidate)
    {
    
        [self superAutorelease];
        
        /* Cancel our sources. Note that they need to be resumed to do so, which is why we enable them. */
        
        al_set_dispatch_source_resumed(mOutgoingDataSource, &mOutgoingDataSourceResumed, YES);
        dispatch_source_cancel(mOutgoingDataSource);
        
        al_set_dispatch_source_resumed(mIncomingDataSource, &mIncomingDataSourceResumed, YES);
        dispatch_source_cancel(mIncomingDataSource);
    
    }
    
    if ([self runLoop] == CFRunLoopGetCurrent())
        [super invalidate];
    
    else
    {
    
        CFRunLoopPerformBlock([self runLoop], [NSArray arrayWithObjects: [self replyMode], NSRunLoopCommonModes, nil],
        ^{
        
            [self invalidate];
        
        });
        
        CFRunLoopWakeUp([self runLoop]);
    
    }

}

#pragma mark -
#pragma mark Override Methods
#pragma mark -

- (void)enqueueOutgoingRequestData: (NSData *)requestData
{

        /* Note that we're not checking whether we're valid when this method is called, since the receiver can be invalidated at any time from another thread, and
           therefore the thread calling this method would have no way of knowing whether the receiver would become invalid the instant this method was called. */
        
        NSParameterAssert(requestData && [requestData length]);
    
    @synchronized(mOutgoingRequestData)
    {
    
        [mOutgoingRequestData appendData: requestData];
    
    }
    
    [mStateLock lock];
    
    if ([mStateLock condition])
        al_set_dispatch_source_resumed(mOutgoingDataSource, &mOutgoingDataSourceResumed, YES);
    
    [mStateLock unlock];

}

#pragma mark -
#pragma mark Private Methods
#pragma mark -

- (void)handleIncomingData
{

    BOOL valid = NO;
    unsigned long estimatedDataLength = 0;
    NSMutableData *requestData = nil;
    ssize_t readResult = 0;
    
    /* We don't need to hold the state lock to execute, but we will check if we we're invalidated before we start executing as a fast-path. */
    
    [mStateLock lock];
    valid = [mStateLock condition];
    [mStateLock unlock];
    
        ALConfirmOrPerform(valid, return);
    
    estimatedDataLength = dispatch_source_get_data(mIncomingDataSource);
    
    if (!estimatedDataLength)
        estimatedDataLength = 0x1000;
    
        /* Verify that estimatedDataLength can be safely converted to an NSUInteger as the argument to dataWithLength: */
        
        ALAssertOrPerform(ALIntValidValueForObject(estimatedDataLength, NSUInteger), goto failed);
    
    requestData = [NSMutableData dataWithLength: estimatedDataLength];
    
        ALAssertOrPerform(requestData, goto failed);
    
    do
    {
    
            /* Verify that [requestData length] can be safely converted to size_t for the third argument to read(). */
            
            ALAssertOrPerform(ALIntValidValueForObject([requestData length], size_t), goto failed);
        
        errno = 0;
        readResult = read(mReadDescriptor.descriptor, [requestData mutableBytes], [requestData length]);
    
    } while (readResult == -1 && errno == EINTR);
    
        /* Check the result of read() to make sure we read some data, or that we failed due to no data being available. If neither is the case,
           then the remote end probably died, so we need to invalidate ourself. */
        
        #warning debug
        ALAssertOrPerform(readResult > 0 || (readResult == -1 && errno == EAGAIN), NSLog(@"Couldn't read; stack trace: %@", [NSThread callStackSymbols]); goto failed);
        
        /* Verify that we can convert readResult to an NSUInteger, for the call to -setLength:. */
        
        ALAssertOrPerform(ALIntValidValueForObject(readResult, NSUInteger), goto failed);
    
    [requestData setLength: readResult];
    
    /* Let the superclass know we have more data. */
    
    CFRunLoopPerformBlock([self runLoop], [NSArray arrayWithObjects: [self replyMode], NSRunLoopCommonModes, nil],
    ^{
    
        if ([self valid])
            [self handleIncomingRequestData: requestData];
    
    });
    
    CFRunLoopWakeUp([self runLoop]);
    return;
    
    failed:
    {
    
        [self invalidate];
    
    }

}

- (void)handleOutgoingData
{

    BOOL valid = NO;
    unsigned long estimatedDataLength = 0;
    NSUInteger outgoingRequestDataLength = 0,
               dataLength = 0;
    NSData *data = nil;
    ssize_t writeResult = 0;
    
    /* We don't need to hold the state lock to execute, but we will check if we we're invalidated before we start executing as a fast-path. */
    
    [mStateLock lock];
    valid = [mStateLock condition];
    [mStateLock unlock];
    
        ALConfirmOrPerform(valid, return);
    
    estimatedDataLength = dispatch_source_get_data(mOutgoingDataSource);
    
    if (!estimatedDataLength)
        estimatedDataLength = 0x1000;
    
    @synchronized(mOutgoingRequestData)
    {
    
        outgoingRequestDataLength = [mOutgoingRequestData length];
        
            /* First of all, we better have some outgoing data or else we shouldn't have been called! */
            
            ALAssertOrPerform(outgoingRequestDataLength, goto failed);
            
            /* Verify that estimatedDataLength can be converted to NSUInteger. */
            
            ALAssertOrPerform(ALIntValidValueForObject(estimatedDataLength, NSUInteger), goto failed);
        
        dataLength = ALMin(estimatedDataLength, outgoingRequestDataLength);
        data = [mOutgoingRequestData subdataWithRange: NSMakeRange(0, dataLength)];
    
    }
    
    do
    {
    
            ALAssertOrPerform(ALIntValidValueForObject(dataLength, size_t), goto failed);
        
        errno = 0;
        writeResult = write(mWriteDescriptor.descriptor, [data bytes], dataLength);
    
    } while (writeResult == -1 && errno == EINTR);
    
        ALAssertOrPerform(writeResult > 0 || (writeResult == -1 && errno == EAGAIN), goto failed);
    
    if (writeResult > 0)
    {
    
        /* If we actually wrote some data, truncate the beginning part of mOutgoingRequestData that we just wrote. */
        
        @synchronized(mOutgoingRequestData)
        {
        
            [mOutgoingRequestData replaceBytesInRange: NSMakeRange(0, writeResult) withBytes: nil length: 0];
            outgoingRequestDataLength = [mOutgoingRequestData length];
        
        }
        
        if (!outgoingRequestDataLength)
        {
        
            [mStateLock lock];
            
            if ([mStateLock condition])
                al_set_dispatch_source_resumed(mOutgoingDataSource, &mOutgoingDataSourceResumed, NO);
            
            [mStateLock unlock];
        
        }
    
    }
    
    return;
    failed:
    {
    
        [self invalidate];
    
    }

}

@end