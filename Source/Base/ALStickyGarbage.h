#import <Foundation/Foundation.h>

@interface ALStickyGarbage : NSObject
{

@private
    
    NSPointerArray *pointers;
    NSTimer *dumpStickyGarbageTimer;

}

/* Creation */

+ (ALStickyGarbage *)currentStickyGarbage;

/* Methods */

/* This method ensures that the supplied pointer sticks around for at least the next run of the run loop. */

- (void)markStickyGarbage: (const void *__strong)pointer;
- (void)dumpStickyGarbage;

@end