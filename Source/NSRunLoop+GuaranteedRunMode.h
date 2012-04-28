#import <Foundation/Foundation.h>

@interface NSRunLoop (GuaranteedRunMode)

/* If a run loop has nothing scheduled for a run loop mode, this will simply block until the given date. This can be useful if you
   expect a timer or source to be added to a certain mode that may not exist yet. */

- (SInt32)guaranteedRunMode: (NSString *)mode timeout: (NSTimeInterval)timeout returnAfterSourceHandled: (BOOL)returnAfterSourceHandled;

@end