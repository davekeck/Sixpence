#import "NSScreen+FurthestScreen.h"

@implementation NSScreen (FurthestScreen)

+ (NSScreen *)furthestScreenInDirection: (NSScreen_FurthestScreen_Direction)direction
{

    NSArray *screens = [NSScreen screens];
    NSScreen *currentScreen,
             *result = nil;
    
    for (currentScreen in screens)
    {
    
        if (direction == NSScreen_FurthestScreen_Direction_Up && (!result || [currentScreen frame].origin.y > [result frame].origin.y))
            result = currentScreen;
        
        else if (direction == NSScreen_FurthestScreen_Direction_Down && (!result || [currentScreen frame].origin.y < [result frame].origin.y))
            result = currentScreen;
        
        else if (direction == NSScreen_FurthestScreen_Direction_Left && (!result || [currentScreen frame].origin.x < [result frame].origin.x))
            result = currentScreen;
        
        else if (direction == NSScreen_FurthestScreen_Direction_Right && (!result || [currentScreen frame].origin.x > [result frame].origin.x))
            result = currentScreen;
    
    }
    
    return result;

}

@end