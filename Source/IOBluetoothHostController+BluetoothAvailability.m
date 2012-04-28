// Garbage Collection
//   o verified uses of &

#import "IOBluetoothHostController+BluetoothAvailability.h"

#pragma mark Category Implementations
#pragma mark -

@interface IOBluetoothPreferences : NSObject

+ (id)sharedPreferences;
@property BOOL poweredOn;

@end

@implementation IOBluetoothHostController (BluetoothAvailability)

#pragma mark -
#pragma mark Methods
#pragma mark -

- (BOOL)bluetoothCapable
{

    return ([IOBluetoothHostController defaultController] != nil);

}

- (BOOL)bluetoothEnabled
{

        ALConfirmOrPerform([self bluetoothCapable], return NO);
    
    #warning private APIs
    if (NSClassFromString(@"IOBluetoothPreferences") && [(id)NSClassFromString(@"IOBluetoothPreferences") respondsToSelector: @selector(sharedPreferences)])
    {
    
        IOBluetoothPreferences *bluetoothPreferences = nil;
        
        bluetoothPreferences = [(id)NSClassFromString(@"IOBluetoothPreferences") sharedPreferences];
        
        if (bluetoothPreferences && [bluetoothPreferences respondsToSelector: @selector(poweredOn)])
            return [bluetoothPreferences poweredOn];
    
    }
    
    return NO;

}

@end