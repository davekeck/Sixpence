#import "IOBluetoothDevice+CachedIsConnected.h"

@implementation IOBluetoothDevice (CachedIsConnected)

- (BOOL)cachedIsConnected
{

    return ([self connectionHandle] != kBluetoothConnectionHandleNone);

}

@end