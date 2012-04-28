#import "ALGradientShadowLabelCell.h"

#import "NSGraphicsContext+FlipRect.h"

#import "ALStyledTextCompositor.h"

#pragma mark Class Implementations
#pragma mark -

@implementation ALGradientShadowLabelCell

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
#pragma mark -

@synthesize textGradient;
@synthesize textShadow;

#pragma mark -
#pragma mark Override Methods
#pragma mark -

- (void)drawWithFrame: (NSRect)frame inView: (NSView *)view
{

    ALStyledTextCompositor *compositor = nil;
    
    compositor = [ALStyledTextCompositor startWithRect: frame textGradient: textGradient textShadow: textShadow];
    [NSGraphicsContext saveGraphicsState];
    
    [NSGraphicsContext flipRect: frame];
    [super drawWithFrame: frame inView: view];
    
    [NSGraphicsContext restoreGraphicsState];
    [compositor finish];

}

@end