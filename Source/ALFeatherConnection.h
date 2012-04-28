#import <Foundation/Foundation.h>

/* Three scalar types are supported as argument and return types: Int, UInt, and Float. */

typedef int64_t ALFeatherInt;
typedef uint64_t ALFeatherUInt;
typedef Float64 ALFeatherFloat;
typedef ALFeatherUInt ALFeatherBOOL;

extern NSString *const ALFeatherConnectionInvalidatedNotification;

/* Use this macro as a convenient way to perform one-line invocations and handle errors. You must not attempt to access a return value until
   you've determined that the invocation succeeded. */

#define ALFeatherInvoke(connection, invocation, action)     \
({                                                          \
                                                            \
        NSParameterAssert(connection);                      \
                                                            \
    invocation;                                             \
                                                            \
    if (![connection lastInvocationSucceeded])              \
    {                                                       \
                                                            \
        action;                                             \
                                                            \
    }                                                       \
                                                            \
})

@interface ALFeatherConnection : NSObject

/* Creation */

- (id)initWithLocalServerObject: (NSObject *)localServerObject remoteServerProtocol: (Protocol *)remoteServerProtocol;

/* -invalidate must only be called on the thread on which the connection was created. */

- (void)invalidate;

/* Properties */

@property(nonatomic, readonly, assign) BOOL valid;
@property(nonatomic, readonly, assign) BOOL lastInvocationSucceeded;
@property(nonatomic, readonly, retain) __attribute__((NSObject)) CFRunLoopRef runLoop;

/* Methods */
/* Note that it's possible for the connection to become invalid while sending an invocation to the proxy object, and therefore
   the ALFeatherConnectionInvalidatedNotification notification can be posted from within the invocation stack frame. */

- (id)remoteServerProxy;
- (void)handleIncomingRequestData: (NSData *)requestData;

/* This is mode that the connection runs the run loop in while waiting for a reply to a synchronous (non-oneway) invocation. */

- (NSString *)replyMode;

/* Subclass Methods */

- (void)enqueueOutgoingRequestData: (NSData *)requestData;

@end