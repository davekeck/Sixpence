// Garbage Collection
//   o verified uses of &

#import "NSScreen+Fade.h"

#pragma mark Category Implementations
#pragma mark -

@implementation NSScreen (Fade)

static CGDisplayFadeReservationToken gFadeReservationToken = kCGDisplayFadeReservationInvalidToken;

#pragma mark -
#pragma mark Methods
#pragma mark -

+ (BOOL)startFadeWithDuration: (NSTimeInterval)duration waitUntilFinished: (BOOL)waitUntilFinished
{

    CGError acquireDisplayFadeReservationResult = 0,
            displayFadeResult = 0;
    
        /* If a fade is already in progress, then we can't start another one. */
        
        ALAssertOrRaise(gFadeReservationToken == kCGDisplayFadeReservationInvalidToken);
    
    acquireDisplayFadeReservationResult = CGAcquireDisplayFadeReservation(kCGMaxDisplayReservationInterval, &gFadeReservationToken);
    
        /* Check if we failed, or if the fade reservation token is invalid. */
        
        ALAssertOrPerform(acquireDisplayFadeReservationResult == kCGErrorSuccess, goto failed);
    
    displayFadeResult = CGDisplayFade(gFadeReservationToken, duration, kCGDisplayBlendNormal, kCGDisplayBlendSolidColor, 0.0, 0.0, 0.0, waitUntilFinished);
    
        ALAssertOrPerform(displayFadeResult == kCGErrorSuccess, goto failed);
    
    return YES;
    
    failed:
    {
    
        if (gFadeReservationToken != kCGDisplayFadeReservationInvalidToken)
            CGReleaseDisplayFadeReservation(gFadeReservationToken),
            gFadeReservationToken = kCGDisplayFadeReservationInvalidToken;
    
    }
    
    return NO;

}

+ (BOOL)finishFadeWithDuration: (NSTimeInterval)duration waitUntilFinished: (BOOL)waitUntilFinished
{

    CGError displayFadeResult = 0;
    BOOL result = NO;
    
        /* If no fade is in progress, then there's nothing to finish. */
        
        ALAssertOrRaise(gFadeReservationToken != kCGDisplayFadeReservationInvalidToken);
    
    displayFadeResult = CGDisplayFade(gFadeReservationToken, duration, kCGDisplayBlendSolidColor, kCGDisplayBlendNormal, 0.0, 0.0, 0.0, waitUntilFinished);
    
        ALAssertOrPerform(displayFadeResult == kCGErrorSuccess, goto cleanup);
    
    result = YES;
    
    cleanup:
    {
    
        if (gFadeReservationToken != kCGDisplayFadeReservationInvalidToken)
            CGReleaseDisplayFadeReservation(gFadeReservationToken),
            gFadeReservationToken = kCGDisplayFadeReservationInvalidToken;
    
    }
    
    return result;

}

@end