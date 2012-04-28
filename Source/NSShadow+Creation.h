#import <Cocoa/Cocoa.h>

@interface NSShadow (Creation)

/* Creation */

- (NSShadow *)initWithColor: (NSColor *)color offset: (NSSize)offset blurRadius: (CGFloat)blurRadius;
+ (NSShadow *)shadowWithColor: (NSColor *)color offset: (NSSize)offset blurRadius: (CGFloat)blurRadius;

@end