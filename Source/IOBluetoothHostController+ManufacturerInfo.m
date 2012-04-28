// Garbage Collection
//   o verified uses of &

#import "IOBluetoothHostController+ManufacturerInfo.h"

#pragma mark Public Constants
#pragma mark -

BluetoothManufacturerName IOBluetoothManufacturerIdentiferUnknown = -1;

#pragma mark Category Implementations
#pragma mark -

@implementation IOBluetoothHostController (ManufacturerInfo)

#pragma mark -
#pragma mark Methods
#pragma mark -

- (BluetoothManufacturerName)manufacturerIdentifer
{

    BluetoothHCIVersionInfo bluetoothHCIVersionInfo;
    IOReturn bluetoothGetVersionResult = 0;
    BluetoothManufacturerName result = 0;
    
    /* By default, we return -1. */
    
    result = (BluetoothManufacturerName)IOBluetoothManufacturerIdentiferUnknown;
    bluetoothGetVersionResult = IOBluetoothGetVersion(nil, &bluetoothHCIVersionInfo);
    
    if (bluetoothGetVersionResult == kIOReturnSuccess)
        result = bluetoothHCIVersionInfo.manufacturerName;
    
    return result;

}

@end