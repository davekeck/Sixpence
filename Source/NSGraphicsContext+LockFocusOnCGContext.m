#import "NSGraphicsContext+LockFocusOnCGContext.h"

@implementation NSGraphicsContext (LockFocusOnCGContext)

+ (void)lockFocusOnCGContext: (CGContextRef)cgContext flipped: (BOOL)flipped
{

    NSGraphicsContext *context = nil;
    
        NSParameterAssert(cgContext);
    
    context = [NSGraphicsContext graphicsContextWithGraphicsPort: cgContext flipped: flipped];
    
        ALAssertOrPerform(context, return);
    
    [NSGraphicsContext setCurrentContext: context];

}

@end