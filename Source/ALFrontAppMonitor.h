#import <Cocoa/Cocoa.h>

@interface ALFrontAppMonitor : ALSingleton

/* Properties */

@property(nonatomic, readonly) NSString *frontAppDidSwitchNotificationName;

@end