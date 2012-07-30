#import <Foundation/Foundation.h>

/* Constants */

extern const void *NSObject_Invocation_ParameterNil;
extern const BOOL NSObject_Invocation_ParameterNO;
extern const BOOL NSObject_Invocation_ParameterYES;

@interface NSObject (Invocation)

/* Methods */

/* If modes is nil in any of the below methods, it is assumed NSRunLoopCommonModes. */

- (NSInvocation *)performSelector: (SEL)selector arguments: (void *)firstArgument, ...;
- (NSInvocation *)asyncPerformSelector: (SEL)selector modes: (NSSet *)modes arguments: (void *)firstArgument, ...;
- (NSInvocation *)asyncPerformSelector: (SEL)selector modes: (NSSet *)modes delay: (NSTimeInterval)delay arguments: (void *)firstArgument, ...;

- (NSInvocation *)performSelector: (SEL)selector onThread: (NSThread *)thread modes: (NSSet *)modes arguments: (void *)firstArgument, ...;
- (NSInvocation *)asyncPerformSelector: (SEL)selector onThread: (NSThread *)thread modes: (NSSet *)modes arguments: (void *)firstArgument, ...;

- (NSInvocation *)asyncPerformSelectorOnNewThread: (SEL)selector arguments: (void *)firstArgument, ...;
- (NSInvocation *)asyncPerformSelectorOnNewThreadWithAutoreleasePool: (SEL)selector arguments: (void *)firstArgument, ...;

- (NSInvocation *)invocationForSelector: (SEL)selector arguments: (void *)firstArgument, ...;
- (NSInvocation *)invocationForSelector: (SEL)selector firstArgument: (void *)firstArgument argumentList: (va_list)argumentList;

@end