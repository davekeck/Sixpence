#import <Foundation/Foundation.h>
#define BLUETOOTH_VERSION_USE_CURRENT
#import <IOBluetooth/IOBluetooth.h>

@interface IOBluetoothDevice (WithAddressString)

+ (IOBluetoothDevice *)withAddressString: (NSString *)addressString;

@end