#import "NSWindow+CenterInScreen.h"

@implementation NSWindow (CenterInScreen)

- (void)centerInScreen: (NSScreen *)screen
{

    NSRect screenFrame,
           newReceiverFrame;
    
        NSParameterAssert(screen);
    
    screenFrame = [screen frame];
    newReceiverFrame = [self frame];
    newReceiverFrame.origin = NSMakePoint(screenFrame.origin.x + floor((screenFrame.size.width - newReceiverFrame.size.width) / 2.0),
                                          screenFrame.origin.y + floor((screenFrame.size.height - newReceiverFrame.size.height) / 2.0));
    
    [self setFrame: newReceiverFrame display: [self isVisible]];

}

@end