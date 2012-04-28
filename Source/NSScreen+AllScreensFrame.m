#import "NSScreen+AllScreensFrame.h"

@implementation NSScreen (AllScreensFrame)

+ (NSRect)allScreensFrame
{

    NSArray *screens = nil;
    NSScreen *currentScreen = nil;
    NSRect result;
    
    result = NSZeroRect;
    
    screens = [NSScreen screens];
    
    for (currentScreen in screens)
        result = NSUnionRect(result, [currentScreen frame]);
    
    return result;

}

@end