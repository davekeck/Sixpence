#import "ALThreeImageButtonCell.h"

#import "NSBitmapImageRep+Creation.h"
#import "NSBitmapImageRep+LockFocus.h"

#import "ALHighlightedButtonCompositor.h"

#pragma mark Class Implementations
#pragma mark -

@implementation ALThreeImageButtonCell

- (void)dealloc
{

    [self setLeftCapImage: nil];
    [self setCenterFillImage: nil];
    [self setRightCapImage: nil];
    
    [super dealloc];

}

#pragma mark -
#pragma mark Properties

@synthesize leftCapImage;
@synthesize centerFillImage;
@synthesize rightCapImage;

#pragma mark -
#pragma mark Override Methods
#pragma mark -

- (void)drawBezelWithFrame: (NSRect)frame inView: (NSView *)view
{

    ALHighlightedButtonCompositor *compositor = nil;
    BOOL highlight = NO;
    
    highlight = [self isHighlighted];
    
    if (highlight)
        compositor = [ALHighlightedButtonCompositor startWithRect: frame highlightColor: [[NSColor blackColor] colorWithAlphaComponent: 0.25]];
    
//    if ([NSApp isActive] && [[view window] isKeyWindow] && [[view window] firstResponder] == view)
//        NSSetFocusRingStyle(NSFocusRingAbove);
    
    NSDrawThreePartImage(frame, leftCapImage, centerFillImage, rightCapImage, NO, NSCompositeSourceOver, 1.0, [view isFlipped]);
    
    if (highlight)
        [compositor finish];

}

@end