/* This class is thread-safe. Only one block can be registered for each signal. */

#import <Foundation/Foundation.h>

@interface ALSignalMonitor : ALSingleton
{

@private
    
    NSPointerArray *entries;

}

- (void)registerForSignal: (int)signalNumber onQueue: (dispatch_queue_t)queue withBlock: (dispatch_block_t)block;
- (void)unregisterBlockForSignal: (int)signalNumber;

- (void)setSignal: (int)signalNumber ignored: (BOOL)ignored;

@end