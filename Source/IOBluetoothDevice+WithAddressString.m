#import "IOBluetoothDevice+WithAddressString.h"

@implementation IOBluetoothDevice (WithAddressString)

+ (IOBluetoothDevice *)withAddressString: (NSString *)addressString
{

    BluetoothDeviceAddress bluetoothDeviceAddress;
    IOReturn createDeviceAddressResult = 0;
    IOBluetoothDevice *result = nil;
    
        NSParameterAssert(addressString && [addressString length]);
    
    createDeviceAddressResult = IOBluetoothNSStringToDeviceAddress(addressString, &bluetoothDeviceAddress);
    
        ALAssertOrPerform(createDeviceAddressResult == kIOReturnSuccess, goto cleanup);
    
    result = [IOBluetoothDevice withAddress: &bluetoothDeviceAddress];
    
        ALAssertOrPerform(result, goto cleanup);
    
    cleanup:
    {
    }
    
    return result;

}

@end