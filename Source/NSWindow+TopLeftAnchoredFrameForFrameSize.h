#import <Cocoa/Cocoa.h>

@interface NSWindow (TopLeftAnchoredFrameForFrameSize)

- (NSRect)topLeftAnchoredFrameForFrameSize: (NSSize)newFrameSize;
- (NSRect)topLeftAnchoredFrameForContentViewSize: (NSSize)newContentViewSize;

@end