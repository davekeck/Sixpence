#import <Foundation/Foundation.h>

NS_INLINE void ALSetTimer(NSTimer **oldTimer, NSTimer *newTimer)
{
        NSCParameterAssert(oldTimer);
        ALConfirmOrPerform(*oldTimer != newTimer, return);
    
    [newTimer retain];
    [*oldTimer invalidate];
    [*oldTimer release];
    *oldTimer = newTimer;
}