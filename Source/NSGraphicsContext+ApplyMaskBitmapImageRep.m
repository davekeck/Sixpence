#import "NSGraphicsContext+ApplyMaskBitmapImageRep.h"

#import "NSGraphicsContext+LockFocusOnCGContext.h"

@implementation NSGraphicsContext (ApplyMaskBitmapImageRep)

- (void)applyMaskBitmapImageRep: (NSBitmapImageRep *)maskBitmapImageRep
{

    CGContextRef cgContext = nil;
    CGImageRef maskImage = nil;
    NSRect bounds;
    
        NSParameterAssert(maskBitmapImageRep);
    
    cgContext = [self graphicsPort];
    
        ALAssertOrPerform(cgContext, return);
    
    maskImage = [maskBitmapImageRep CGImage];
    
        ALAssertOrPerform(maskImage, return);
    
    bounds = NSMakeRect(0.0, 0.0, [maskBitmapImageRep pixelsWide], [maskBitmapImageRep pixelsHigh]);
    
    CGContextClipToMask(cgContext, NSRectToCGRect(bounds), maskImage);
    
    /* Finally, lock focus on the CGContext so that any drawing from here on out has the mask applied. */
    
    [NSGraphicsContext lockFocusOnCGContext: cgContext flipped: [self isFlipped]];

}

@end