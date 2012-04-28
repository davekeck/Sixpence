#import "NSGraphicsContext+FlipRect.h"

#pragma mark Category Implementations
#pragma mark -

@implementation NSGraphicsContext (FlipRect)

#pragma mark -
#pragma mark Creation
#pragma mark -

+ (NSAffineTransform *)transformForFlippedRect: (NSRect)rect
{

    NSAffineTransform *result = nil;
    NSPoint rectOriginAfterFlip;
    
    result = [NSAffineTransform transform];
    
        ALAssertOrPerform(result, return nil);
    
    [result scaleXBy: 1.0 yBy: -1.0];
    
    rectOriginAfterFlip = [result transformPoint: rect.origin];
    
    [result translateXBy: 0.0 yBy: (rectOriginAfterFlip.y - rect.origin.y - rect.size.height)];
    
    return result;

}

#pragma mark -
#pragma mark Methods
#pragma mark -

+ (NSAffineTransform *)flipRect: (NSRect)rect
{

    NSAffineTransform *result = nil;
    
    result = [NSGraphicsContext transformForFlippedRect: rect];
    
        ALAssertOrPerform(result, return nil);
    
    [result concat];
    
    return result;

}

@end