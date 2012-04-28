#import "ALSignalMonitor.h"

#import <signal.h>

@implementation ALSignalMonitor

- (id)initSingleton
{

    if (!(self = [super initSingleton]))
        return nil;
    
    entries = [[NSPointerArray alloc] initWithOptions: (NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality)];
    [entries setCount: NSIG];
    
    return self;

}

- (void)registerForSignal: (int)signalNumber onQueue: (dispatch_queue_t)queue withBlock: (dispatch_block_t)block
{

        NSParameterAssert(ALValueInRangeExclusive(signalNumber, 1, NSIG));
        NSParameterAssert(queue);
        NSParameterAssert(block);
    
    @synchronized(self)
    {
    
        dispatch_source_t notificationPortSource = nil;
        
            ALAssertOrRaise(![entries pointerAtIndex: signalNumber]);
        
        notificationPortSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, signalNumber, 0, queue);
        
            ALAssertOrRaise(notificationPortSource);
        
        dispatch_source_set_event_handler(notificationPortSource, block);
        dispatch_resume(notificationPortSource);
        
        [entries replacePointerAtIndex: signalNumber withPointer: notificationPortSource];
    
    }

}

- (void)unregisterBlockForSignal: (int)signalNumber
{

        NSParameterAssert(ALValueInRangeExclusive(signalNumber, 1, NSIG));
    
    @synchronized(self)
    {
    
        dispatch_source_t notificationPortSource = nil;
        
        notificationPortSource = [entries pointerAtIndex: signalNumber];
        
            ALConfirmOrPerform(notificationPortSource, return);
        
        dispatch_source_cancel(notificationPortSource);
        dispatch_release(notificationPortSource);
        
        [entries replacePointerAtIndex: signalNumber withPointer: nil];
    
    }

}

- (void)setSignal: (int)signalNumber ignored: (BOOL)ignored
{

    void *signalResult = nil;
    
        NSParameterAssert(ALValueInRangeExclusive(signalNumber, 1, NSIG));
    
    signalResult = signal(signalNumber, (ignored ? SIG_IGN : SIG_DFL));
    
        ALAssertOrRaise(signalResult != SIG_ERR);

}

@end