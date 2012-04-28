#import "CATransaction+DisableAnimation.h"

@implementation CATransaction (DisableAnimation)

+ (void)disableAnimation
{

    [CATransaction begin];
    
    [CATransaction setValue: (id)kCFBooleanTrue forKey: kCATransactionDisableActions];

}

+ (void)enableAnimation
{

    [CATransaction commit];

}

@end