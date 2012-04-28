#import <Foundation/Foundation.h>

#import "ALFeatherConnection.h"

@interface ALFeatherDescriptorConnection : ALFeatherConnection

- (id)initWithReadDescriptor: (int)readDescriptor writeDescriptor: (int)writeDescriptor
    localServerObject: (NSObject *)localServerObject remoteServerProtocol: (Protocol *)remoteServerProtocol;

@end