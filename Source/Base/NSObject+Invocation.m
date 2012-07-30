#import "NSObject+Invocation.h"

#pragma mark - Constants -

const void *NSObject_Invocation_ParameterNil = nil;
const BOOL NSObject_Invocation_ParameterNO = NO;
const BOOL NSObject_Invocation_ParameterYES = YES;

#pragma mark - Private Method Interfaces -

@interface NSObject (Invocation_Private)

- (void)threadInvokeWithAutoreleasePool: (NSInvocation *)invocation;

@end

#pragma mark - Category Implementations -

@implementation NSObject (Invocation)

#pragma mark - Methods -

- (NSInvocation *)performSelector: (SEL)selector arguments: (void *)firstArgument, ...
{

    NSInvocation *invocation = nil;
    va_list argumentList;
    
    va_start(argumentList, firstArgument);
    invocation = [self invocationForSelector: selector firstArgument: firstArgument argumentList: argumentList];
    va_end(argumentList);
    
    [invocation invoke];
    
    return invocation;

}

- (NSInvocation *)asyncPerformSelector: (SEL)selector modes: (NSSet *)modes arguments: (void *)firstArgument, ...
{

    NSInvocation *invocation = nil;
    va_list argumentList;
    
    va_start(argumentList, firstArgument);
    invocation = [self invocationForSelector: selector firstArgument: firstArgument argumentList: argumentList];
    va_end(argumentList);
    
    [invocation performSelector: @selector(invoke) withObject: nil afterDelay: 0.0
        inModes: [((modes && [modes count]) ? modes : [NSSet setWithObject: NSRunLoopCommonModes]) allObjects]];
    
    return invocation;

}

- (NSInvocation *)asyncPerformSelector: (SEL)selector modes: (NSSet *)modes delay: (NSTimeInterval)delay arguments: (void *)firstArgument, ...
{

    NSInvocation *invocation = nil;
    va_list argumentList;
    
        NSParameterAssert(delay >= 0.0);
    
    va_start(argumentList, firstArgument);
    invocation = [self invocationForSelector: selector firstArgument: firstArgument argumentList: argumentList];
    va_end(argumentList);
    
    [invocation performSelector: @selector(invoke) withObject: nil afterDelay: delay
        inModes: [((modes && [modes count]) ? modes : [NSSet setWithObject: NSRunLoopCommonModes]) allObjects]];
    
    return invocation;

}

- (NSInvocation *)performSelector: (SEL)selector onThread: (NSThread *)thread modes: (NSSet *)modes arguments: (void *)firstArgument, ...
{

    NSInvocation *invocation = nil;
    va_list argumentList;
    
        NSParameterAssert(thread);
    
    va_start(argumentList, firstArgument);
    invocation = [self invocationForSelector: selector firstArgument: firstArgument argumentList: argumentList];
    va_end(argumentList);
    
    [invocation performSelector: @selector(invoke) onThread: thread withObject: nil waitUntilDone: YES
        modes: [((modes && [modes count]) ? modes : [NSSet setWithObject: NSRunLoopCommonModes]) allObjects]];
    
    return invocation;

}

- (NSInvocation *)asyncPerformSelector: (SEL)selector onThread: (NSThread *)thread modes: (NSSet *)modes arguments: (void *)firstArgument, ...
{

    NSInvocation *invocation = nil;
    va_list argumentList;
    
        NSParameterAssert(thread);
    
    va_start(argumentList, firstArgument);
    invocation = [self invocationForSelector: selector firstArgument: firstArgument argumentList: argumentList];
    va_end(argumentList);
    
    [invocation performSelector: @selector(invoke) onThread: thread withObject: nil waitUntilDone: NO
        modes: [((modes && [modes count]) ? modes : [NSSet setWithObject: NSRunLoopCommonModes]) allObjects]];
    
    return invocation;

}

- (NSInvocation *)asyncPerformSelectorOnNewThread: (SEL)selector arguments: (void *)firstArgument, ...
{

    NSInvocation *invocation = nil;
    va_list argumentList;
    
    va_start(argumentList, firstArgument);
    invocation = [self invocationForSelector: selector firstArgument: firstArgument argumentList: argumentList];
    va_end(argumentList);
    
    [NSThread detachNewThreadSelector: @selector(invoke) toTarget: invocation withObject: nil];
    
    return invocation;

}

- (NSInvocation *)asyncPerformSelectorOnNewThreadWithAutoreleasePool: (SEL)selector arguments: (void *)firstArgument, ...
{

    NSInvocation *invocation = nil;
    va_list argumentList;
    
    va_start(argumentList, firstArgument);
    invocation = [self invocationForSelector: selector firstArgument: firstArgument argumentList: argumentList];
    va_end(argumentList);
    
    [NSThread detachNewThreadSelector: @selector(threadInvokeWithAutoreleasePool:) toTarget: self withObject: invocation];
    
    return invocation;

}

- (NSInvocation *)invocationForSelector: (SEL)selector arguments: (void *)firstArgument, ...
{

    NSInvocation *invocation = nil;
    va_list argumentList;
    
    va_start(argumentList, firstArgument);
    invocation = [self invocationForSelector: selector firstArgument: firstArgument argumentList: argumentList];
    va_end(argumentList);
    
    return invocation;

}

- (NSInvocation *)invocationForSelector: (SEL)selector firstArgument: (void *)firstArgument argumentList: (va_list)argumentList
{

    NSMethodSignature *methodSignature = nil;
    NSInvocation *invocation = nil;
    NSInteger i = 0;
    
        NSParameterAssert(selector);
    
    methodSignature = [self methodSignatureForSelector: selector];
    
        ALAssertOrPerform(methodSignature, return nil);
    
    invocation = [NSInvocation invocationWithMethodSignature: methodSignature];
    [invocation setTarget: self];
    [invocation setSelector: selector];
    
    /* The first two arguments are always present: self and _cmd (see NSMethodSignature docs), so if
       we have any "real" arguments, then -numberOfArguments must be greater than 2. */
    
    for (i = 2; i < [methodSignature numberOfArguments]; i++)
        [invocation setArgument: (i == 2 ? firstArgument : va_arg(argumentList, void *)) atIndex: i];
    
    /* This is required for both RC and GC. In both cases, this will cause the invocation's target and arguments to be retained until
       the invocation has completed. */
    
    [invocation retainArguments];
    
    return invocation;

}

#pragma mark - Private Methods -

- (void)threadInvokeWithAutoreleasePool: (NSInvocation *)invocation
{

    NSAutoreleasePool *pool = nil;
    
        NSParameterAssert(invocation);
    
    pool = [[NSAutoreleasePool alloc] init];
    
    [invocation invoke];
    
    [pool release],
    pool = nil;

}

@end