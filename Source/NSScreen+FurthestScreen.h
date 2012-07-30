#import <Cocoa/Cocoa.h>

enum
{

    NSScreen_FurthestScreen_Direction_Up,
    NSScreen_FurthestScreen_Direction_Down,
    NSScreen_FurthestScreen_Direction_Left,
    NSScreen_FurthestScreen_Direction_Right

}; typedef int NSScreen_FurthestScreen_Direction;

@interface NSScreen (FurthestScreen)

+ (NSScreen *)furthestScreenInDirection: (NSScreen_FurthestScreen_Direction)direction;

@end