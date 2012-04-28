#import "IOBluetoothDevice+IsEqualToBluetoothDevice.h"

@implementation IOBluetoothDevice (IsEqualToBluetoothDevice)

- (BOOL)isEqualToBluetoothDevice: (IOBluetoothDevice *)otherBluetoothDevice
{

    const BluetoothDeviceAddress *deviceAddress1,
                                 *deviceAddress2;
    
        NSParameterAssert(otherBluetoothDevice);
    
    deviceAddress1 = [self getAddress];
    
        ALAssertOrRaise(deviceAddress1);
    
    deviceAddress2 = [otherBluetoothDevice getAddress];
    
        ALAssertOrRaise(deviceAddress2);
    
    return (!memcmp(deviceAddress1, deviceAddress2, sizeof(*deviceAddress2)));

}

@end