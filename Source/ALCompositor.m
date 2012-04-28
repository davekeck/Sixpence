#import "ALCompositor.h"

#import "NSBitmapImageRep+Creation.h"
#import "NSBitmapImageRep+LockFocus.h"

#import "NSImageRep+Encapsulate.h"

@implementation ALCompositor

#pragma mark -
#pragma mark Creation
#pragma mark -

- (void)dealloc
{

    [self setRect: NSZeroRect];
    [self setBitmapImageRep: nil];
    [super dealloc];

}

#pragma mark -
#pragma mark Properties
#pragma mark -

@synthesize rect;
@synthesize bitmapImageRep;

#pragma mark -
#pragma mark Subclass Override Methods
#pragma mark -

- (void)willLockFocusOnBitmapImageRep
{
}

- (void)didLockFocusOnBitmapImageRep
{
}

- (void)willUnlockFocusOnBitmapImageRep
{
}

- (void)didUnlockFocusOnBitmapImageRep
{
}

- (void)willDrawBitmapImageRep
{
}

- (void)didDrawBitmapImageRep
{
}

#pragma mark -
#pragma mark Methods
#pragma mark -

+ (id)startWithRect: (NSRect)newRect
{

    NSInteger pixelWidth = 0,
              pixelHeight = 0;
    NSRect bounds;
    NSBitmapImageRep *bitmapImageRep = nil;
    NSAffineTransform *transform = nil;
    ALCompositor *result = nil;
    
        NSParameterAssert(lround(NSWidth(newRect)) > 0 && lround(NSHeight(newRect)) > 0);
    
    pixelWidth = lround(NSWidth(newRect));
    pixelHeight = lround(NSHeight(newRect));
    bounds = NSMakeRect(0.0, 0.0, pixelWidth, pixelHeight);
    bitmapImageRep = [NSBitmapImageRep bitmapImageRepWithPixelsWide: pixelWidth pixelsHigh: pixelHeight];
    
    result = [[[self alloc] init] autorelease];
    [result setRect: newRect];
    [result setBitmapImageRep: bitmapImageRep];
    [result willLockFocusOnBitmapImageRep];
    
    /* Lock focus on our bitmap image rep so that we can draw the mask into it. */
    
    [bitmapImageRep lockFocus];
    NSRectFillUsingOperation(bounds, NSCompositeClear);
    
    /* Offset the drawing so that the text is drawn at our bitmap image rep's origin. */
    
    transform = [NSAffineTransform transform];
    [transform translateXBy: -NSMinX(newRect) yBy: -NSMinY(newRect)];
    [transform concat];
    [result didLockFocusOnBitmapImageRep];
    
    return result;

}

- (void)finish
{

        /* Our rect ivar serves doubly as our flag as to whether we've already been finished (we clear it at the end of this method) to ensure that
           this method isn't called more than once. */
        
        ALAssertOrRaise(!NSIsEmptyRect(rect));
    
    [self willUnlockFocusOnBitmapImageRep];
    [bitmapImageRep unlockFocus];
    [self didUnlockFocusOnBitmapImageRep];
    
    [self willDrawBitmapImageRep];
    [[bitmapImageRep encapsulate] drawAtPoint: rect.origin fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
    [self didDrawBitmapImageRep];
    
    /* Reset our rect to signify that we're finished (so we can throw an error if this method is called again). */
    
    [self setRect: NSZeroRect];

}

@end