#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface CATransaction (DisableAnimation)

+ (void)disableAnimation;
+ (void)enableAnimation;

@end