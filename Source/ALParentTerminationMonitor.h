#import <Foundation/Foundation.h>

/* Class Interfaces */

@interface ALParentTerminationMonitor : ALSingleton

/* Methods */

/* This method can be called any number of times. If it determines that the parent has already terminated (ppid == 1), then the block will be
   immediately enqueued on the global concurrent queue. */

- (void)monitorParentTerminationWithQueue: (dispatch_queue_t)queue block: (dispatch_block_t)block;

@end