#import <Cocoa/Cocoa.h>

@interface NSGraphicsContext (FlipRect)

/* Creation */

+ (NSAffineTransform *)transformForFlippedRect: (NSRect)rect;

/* Methods */

+ (NSAffineTransform *)flipRect: (NSRect)rect;

@end