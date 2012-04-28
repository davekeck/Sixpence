#import <Foundation/Foundation.h>
#define BLUETOOTH_VERSION_USE_CURRENT
#import <IOBluetooth/IOBluetooth.h>

@interface IOBluetoothDevice (CachedIsConnected)

/* Returns whether the receiver is connected without causing any side-effects (as opposed to the stock -isConnected,
   which posts notifications and such.) */

- (BOOL)cachedIsConnected;

@end