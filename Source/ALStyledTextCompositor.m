#import "ALStyledTextCompositor.h"

#import "NSBitmapImageRep+Creation.h"
#import "NSBitmapImageRep+LockFocus.h"

#import "NSGraphicsContext+ApplyMaskBitmapImageRep.h"

#pragma mark -
#pragma mark Class Implementations
#pragma mark -

@implementation ALStyledTextCompositor

#pragma mark -
#pragma mark Creation
#pragma mark -

- (void)dealloc
{

    [self setTextGradient: nil];
    [self setTextShadow: nil];
    [super dealloc];

}

#pragma mark -
#pragma mark Properties

@synthesize textGradient;
@synthesize textShadow;

#pragma mark -
#pragma mark Override Methods
#pragma mark -

- (void)willDrawBitmapImageRep
{

    NSInteger pixelWidth = 0,
              pixelHeight = 0;
    NSRect bounds;
    NSBitmapImageRep *newGradientBitmapImageRep = nil;
    
    pixelWidth = [[self bitmapImageRep] pixelsWide];
    pixelHeight = [[self bitmapImageRep] pixelsHigh];
    bounds = NSMakeRect(0.0, 0.0, pixelWidth, pixelHeight);
    
    newGradientBitmapImageRep = [NSBitmapImageRep bitmapImageRepWithPixelsWide: pixelWidth pixelsHigh: pixelHeight];
    [newGradientBitmapImageRep lockFocus];
    
    /* Draw the gradient, which will be masked by the text. */
    
    NSRectFillUsingOperation(bounds, NSCompositeClear);
    [[NSGraphicsContext currentContext] applyMaskBitmapImageRep: [self bitmapImageRep]];
    [textGradient drawInRect: NSMakeRect(0.0, 0.0, pixelWidth, pixelHeight) angle: 90.0];
    
    [newGradientBitmapImageRep unlockFocus];
    [self setBitmapImageRep: newGradientBitmapImageRep];
    
    [NSGraphicsContext saveGraphicsState];
    [textShadow set];

}

- (void)didDrawBitmapImageRep
{

    [NSGraphicsContext restoreGraphicsState];

}

#pragma mark -
#pragma mark Methods
#pragma mark -

+ (id)startWithRect: (NSRect)rect textGradient: (NSGradient *)textGradient textShadow: (NSShadow *)textShadow
{

    ALStyledTextCompositor *result = nil;
    
    result = [self startWithRect: rect];
    [result setTextGradient: textGradient];
    [result setTextShadow: textShadow];
    
    return result;

}

@end