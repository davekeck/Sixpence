#import <Cocoa/Cocoa.h>

@interface NSGraphicsContext (LockFocusOnCGContext)

+ (void)lockFocusOnCGContext: (CGContextRef)cgContext flipped: (BOOL)flipped;

@end