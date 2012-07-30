#import "NSWindow+TopLeftAnchoredFrameForFrameSize.h"

@implementation NSWindow (TopLeftAnchoredFrameForFrameSize)

- (NSRect)topLeftAnchoredFrameForFrameSize: (NSSize)newFrameSize
{

    NSRect frame = [self frame],
           result = frame;
    
    result.size = newFrameSize;
    
    result.origin.y -= (result.size.height - frame.size.height);
    
    return result;

}

- (NSRect)topLeftAnchoredFrameForContentViewSize: (NSSize)newContentViewSize
{

    CGFloat frameAndContentViewDifference = ([self frame].size.height - [[self contentView] frame].size.height);
    NSSize frameSize;
    
    frameSize = NSMakeSize(newContentViewSize.width,
                           newContentViewSize.height + frameAndContentViewDifference);
    
    return [self topLeftAnchoredFrameForFrameSize: frameSize];

}

@end