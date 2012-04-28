#import "IOBluetoothHostController+HostInfo.h"

#pragma mark Category Implementations
#pragma mark -

@implementation IOBluetoothHostController (HostInfo)

#pragma mark -
#pragma mark Methods
#pragma mark -

- (BOOL)isLaptop
{

    BluetoothClassOfDevice bluetoothDeviceClass = 0;
    BluetoothDeviceClassMajor bluetoothDeviceClassMajor = 0;
    BluetoothDeviceClassMinor bluetoothDeviceClassMinor = 0;
    BOOL result = NO;
    
    bluetoothDeviceClass = [self classOfDevice];
    bluetoothDeviceClassMajor = BluetoothGetDeviceClassMajor(bluetoothDeviceClass);
    bluetoothDeviceClassMinor = BluetoothGetDeviceClassMinor(bluetoothDeviceClass);
    
    result = (bluetoothDeviceClassMajor == kBluetoothDeviceClassMajorComputer &&
                bluetoothDeviceClassMinor == kBluetoothDeviceClassMinorComputerLaptop);
    
    return result;

}

- (BOOL)isDesktop
{

    BluetoothClassOfDevice bluetoothDeviceClass = 0;
    BluetoothDeviceClassMajor bluetoothDeviceClassMajor = 0;
    BluetoothDeviceClassMinor bluetoothDeviceClassMinor = 0;
    BOOL result = NO;
    
    bluetoothDeviceClass = [self classOfDevice];
    bluetoothDeviceClassMajor = BluetoothGetDeviceClassMajor(bluetoothDeviceClass);
    bluetoothDeviceClassMinor = BluetoothGetDeviceClassMinor(bluetoothDeviceClass);
    
    result = (bluetoothDeviceClassMajor == kBluetoothDeviceClassMajorComputer &&
             (bluetoothDeviceClassMinor == kBluetoothDeviceClassMinorComputerDesktopWorkstation ||
              bluetoothDeviceClassMinor == kBluetoothDeviceClassMinorComputerServer));
    
    return result;

}

@end