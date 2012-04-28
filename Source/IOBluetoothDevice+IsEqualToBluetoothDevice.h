#import <Foundation/Foundation.h>
#define BLUETOOTH_VERSION_USE_CURRENT
#import <IOBluetooth/IOBluetooth.h>

@interface IOBluetoothDevice (IsEqualToBluetoothDevice)

- (BOOL)isEqualToBluetoothDevice: (IOBluetoothDevice *)otherBluetoothDevice;

@end