#import <Cocoa/Cocoa.h>

@interface NSView (Encapsulate)

/* These methods simply place the receiver in superview view that's the same size. It places the receiver at (0, 0). */

- (NSView *)encapsulate;
- (id)encapsulateWithViewClass: (Class)viewClass;

@end