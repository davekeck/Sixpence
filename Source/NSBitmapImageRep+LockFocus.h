#import <Cocoa/Cocoa.h>

@interface NSBitmapImageRep (LockFocus)

- (void)lockFocus;
- (void)unlockFocus;

@end