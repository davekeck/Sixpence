#import "NSBitmapImageRep+LockFocus.h"

@implementation NSBitmapImageRep (LockFocus)

#pragma mark - Methods -

- (void)lockFocus
{

    NSGraphicsContext *context = nil;
    
    context = [NSGraphicsContext graphicsContextWithBitmapImageRep: self];
    
        ALAssertOrPerform(context, return);
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext: context];

}

- (void)unlockFocus
{

    [NSGraphicsContext restoreGraphicsState];

}

@end