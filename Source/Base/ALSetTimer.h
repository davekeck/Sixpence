#import <Foundation/Foundation.h>

NS_INLINE void ALSetTimer(NSTimer **oldTimer, NSTimer *newTimer)
{
        NSCParameterAssert(oldTimer);
        ALConfirmOrPerform(*oldTimer != newTimer, return);
    
    #if !__has_feature(objc_arc)
        [newTimer retain];
    #endif
    
    [*oldTimer invalidate];
    
    #if !__has_feature(objc_arc)
        [*oldTimer release];
    #endif
    
    *oldTimer = newTimer;
}