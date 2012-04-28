#import "IOBluetoothHostController+SharedInstance.h"

#pragma mark Category Implementations
#pragma mark -

@implementation IOBluetoothHostController (SharedController)

#pragma mark -
#pragma mark Creation
#pragma mark -

+ (id)sharedInstance
{

    return [ALSingleton sharedInstanceForClass: self];

}

- (id)initSingleton
{

    return [[IOBluetoothHostController defaultController] retain];

}

@end