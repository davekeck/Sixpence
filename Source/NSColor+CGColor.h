#import <Cocoa/Cocoa.h>

@interface NSColor (CGColor)

+ (NSColor *)colorWithCGColor: (CGColorRef)cgColor;
- (CGColorRef)CGColor;

@end