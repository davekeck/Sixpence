#import "NSView+Encapsulate.h"

@implementation NSView (Encapsulate)

- (NSView *)encapsulate
{

    return [self encapsulateWithViewClass: [NSView class]];

}

- (id)encapsulateWithViewClass: (Class)viewClass
{

    NSRect frame;
    NSView *result = nil;
    
        /* Verify that we were given a valid class, and that we don't have a superview. */
        
        NSParameterAssert(viewClass && ![self superview]);
    
    frame = [self frame];
    
    /* Create our resulting parent view, with the same frame size that the child view (the receiver) has. */
    
    result = [[[viewClass alloc] initWithFrame: NSMakeRect(0.0, 0.0, frame.size.width, frame.size.height)] autorelease];
    
//    /* Set the autoresizing mask of the parent view to match the receiver. */
//    
//    [result setAutoresizingMask: [self autoresizingMask]];
    
    [result addSubview: self];
    
//    /* Reset the autoresizing mask to follow the new parent view. The result of this (and the autoresizing adjustment
//       done above) is that the resulting encapsulated view will have the exact same autoresizing properties that the
//       original view had. */
//    
//    [self setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
    
    [self setFrameOrigin: NSZeroPoint];
    
    return result;

}

@end