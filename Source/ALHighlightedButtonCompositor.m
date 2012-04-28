#import "ALHighlightedButtonCompositor.h"

#pragma mark Class Implementations
#pragma mark -

@implementation ALHighlightedButtonCompositor

#pragma mark -
#pragma mark Creation
#pragma mark -

- (void)dealloc
{

    [self setHighlightColor: nil];
    
    [super dealloc];

}

#pragma mark -
#pragma mark Properties

@synthesize highlightColor;

#pragma mark -
#pragma mark Override Methods
#pragma mark -

- (void)willUnlockFocusOnBitmapImageRep
{

    [highlightColor set];
    NSRectFillUsingOperation([self rect], NSCompositeSourceAtop);

}

#pragma mark -
#pragma mark Methods
#pragma mark -

+ (id)startWithRect: (NSRect)rect highlightColor: (NSColor *)highlightColor
{

    ALHighlightedButtonCompositor *result = nil;
    
    result = [self startWithRect: rect];
    
        ALAssertOrPerform(result, return nil);
    
    result.highlightColor = highlightColor;
    
    return result;

}

@end