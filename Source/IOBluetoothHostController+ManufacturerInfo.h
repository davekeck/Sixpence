#import <Foundation/Foundation.h>
#define BLUETOOTH_VERSION_USE_CURRENT
#import <IOBluetooth/IOBluetooth.h>

/* Constants */

extern BluetoothManufacturerName IOBluetoothManufacturerIdentiferUnknown;

@interface IOBluetoothHostController (ManufacturerInfo)

/* This method returns IOBluetoothManufacturerIdentiferUnknown if an error occurs. */

- (BluetoothManufacturerName)manufacturerIdentifer;

@end