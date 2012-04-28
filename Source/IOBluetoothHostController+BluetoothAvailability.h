#import <Foundation/Foundation.h>
#define BLUETOOTH_VERSION_USE_CURRENT
#import <IOBluetooth/IOBluetooth.h>

@interface IOBluetoothHostController (BluetoothAvailability)

- (BOOL)bluetoothCapable;
- (BOOL)bluetoothEnabled;

@end