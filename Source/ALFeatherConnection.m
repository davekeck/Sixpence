#import "ALFeatherConnection.h"

#import <objc/runtime.h>
#import <libkern/OSAtomic.h>

#import "NSRunLoop+GuaranteedRunMode.h"

@class ALFeatherProxy;

@interface ALFeatherConnection ()

@property(nonatomic, readwrite, assign) BOOL valid;
@property(nonatomic, readwrite, assign) BOOL lastInvocationSucceeded;
@property(nonatomic, readwrite, retain) __attribute__((NSObject)) CFRunLoopRef runLoop;
@property(nonatomic, retain) NSObject *localServerObject;
@property(nonatomic, retain) Protocol *remoteServerProtocol;
@property(nonatomic, retain) ALFeatherProxy *remoteServerProxy;

@property(nonatomic, retain) NSMutableData *incomingRequestData;
@property(nonatomic, assign) BOOL waitingForReply;
@property(nonatomic, retain) NSDictionary *reply;

@property(nonatomic, retain) __attribute__((NSObject)) CFRunLoopSourceRef fauxSource;

/* Private Methods */

- (void)sendInvocation: (NSInvocation *)invocation;

- (BOOL)enqueueIncomingRequest: (NSDictionary *)request;
- (BOOL)handleIncomingRequest: (NSDictionary *)request;

- (BOOL)enqueueOutgoingRequest: (NSDictionary *)request;
- (NSDictionary *)waitForReply;

@end

@interface ALFeatherProxy : NSProxy
@property(nonatomic, retain) ALFeatherConnection *connection;
@end

enum
{

    ALFeatherTypeInit,
    
    ALFeatherTypeVoid,
    ALFeatherTypeObject,
    ALFeatherTypeInt64,
    ALFeatherTypeUInt64,
    ALFeatherTypeFloat64,
    
    _ALFeatherTypeLength,
    _ALFeatherTypeFirst = ALFeatherTypeVoid

}; typedef uint8_t ALFeatherType;

#define ALFeatherTypeValid(featherType) ALValueInRangeExclusive(featherType, _ALFeatherTypeFirst, _ALFeatherTypeLength)

@interface ALFeatherArgument : NSObject <NSCoding>

/* Creation */

- (id)initWithType: (ALFeatherType)type value: (void *)value;

/* Properties */

@property(nonatomic, assign) ALFeatherType type;
@property(nonatomic, retain) id <NSObject, NSCoding> objectValue;
@property(nonatomic, assign) uint64_t scalarValue;

/* Methods */

- (id)objectValue;
- (int64_t)int64Value;
- (uint64_t)uint64Value;
- (Float64)float64Value;

@end

@implementation ALFeatherConnection

static ALStringConst(kRequestTypeKey);

/* Invocation request keys */

static ALStringConst(kRequestArgumentsKey);
static ALStringConst(kRequestOnewayKey);

/* Invocation reply keys */

static ALStringConst(kRequestReturnValueKey);
static ALStringConst(kRequestExceptionKey);

ALStringConst(ALFeatherConnectionInvalidatedNotification);

@synthesize valid = mValid;
@synthesize lastInvocationSucceeded = mLastInvocationSucceeded;
@synthesize runLoop = mRunLoop;
@synthesize localServerObject = mLocalServerObject;
@synthesize remoteServerProtocol = mRemoteServerProtocol;
@synthesize remoteServerProxy = mRemoteServerProxy;

@synthesize incomingRequestData = mIncomingRequestData;
@synthesize waitingForReply = mWaitingForReply;
@synthesize reply = mReply;

@synthesize fauxSource = mFauxSource;

static void fauxSourceCallback(void *info) {}

static ALFeatherType validateTypeString(const char *typeString, BOOL returnValue)
{

        NSCParameterAssert(typeString);
    
    if (returnValue && !strcmp(typeString, @encode(void)))
        return ALFeatherTypeVoid;
    
    else if (!strcmp(typeString, @encode(id)))
        return ALFeatherTypeObject;
    
    else if (!strcmp(typeString, @encode(ALFeatherInt)))
        return ALFeatherTypeInt64;
    
    else if (!strcmp(typeString, @encode(ALFeatherUInt)))
        return ALFeatherTypeUInt64;
    
    else if (!strcmp(typeString, @encode(ALFeatherFloat)))
        return ALFeatherTypeFloat64;
    
    return ALFeatherTypeInit;

}

#pragma mark -
#pragma mark Creation
#pragma mark -

- (id)initWithLocalServerObject: (NSObject *)localServerObject remoteServerProtocol: (Protocol *)remoteServerProtocol
{

    CFRunLoopSourceContext fauxSourceContext;
    CFRunLoopSourceRef fauxSource = nil;
    
    if (!(self = [super init]))
        return nil;
    
    [self setLocalServerObject: localServerObject];
    [self setRemoteServerProtocol: remoteServerProtocol];
    [self setRunLoop: CFRunLoopGetCurrent()];
    [self setIncomingRequestData: [NSMutableData data]];
    
    if (mRemoteServerProtocol)
    {
    
        ALFeatherProxy *remoteServerProxy = nil;
        
        remoteServerProxy = [[[ALFeatherProxy alloc] init] autorelease];
        [remoteServerProxy setConnection: self];
        [self setRemoteServerProxy: remoteServerProxy];
    
    }
    
    /* Create our faux source so that CFRunLoopRunInMode et al don't return immediately due to having no sources. */
    
    memset(&fauxSourceContext, 0, sizeof(fauxSourceContext));
    fauxSourceContext.version = 0;
    fauxSourceContext.perform = fauxSourceCallback;
    fauxSource = (CFRunLoopSourceRef)[(id)CFRunLoopSourceCreate(nil, 0, &fauxSourceContext) superAutorelease];
    [self setFauxSource: fauxSource];
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), mFauxSource, (CFStringRef)NSRunLoopCommonModes);
    CFRunLoopWakeUp(CFRunLoopGetCurrent());
    
    /* Retain ourself and we're finished! */
    
    [self superRetain];
    mValid = YES;
    
    return self;

}

- (void)dealloc
{

    [self setReply: nil];
    
    [self setFauxSource: nil];
    [self setRemoteServerProxy: nil];
    [self setIncomingRequestData: nil];
    [self setRunLoop: nil];
    [self setRemoteServerProtocol: nil];
    [self setLocalServerObject: nil];
    
    [super dealloc];

}

- (void)invalidate
{

        ALConfirmOrPerform(mValid, return);
    
    mValid = NO;
    [self superAutorelease];
    
    CFRunLoopSourceInvalidate(mFauxSource);
    CFRunLoopWakeUp(CFRunLoopGetCurrent());
    
    [mRemoteServerProxy setConnection: nil];
    
    /* If we're waiting for a reply to an outgoing invocation, we'll stop the run loop so that we return into -waitForReply. */
    
    if (mWaitingForReply)
        CFRunLoopStop(CFRunLoopGetCurrent());
    
    [[NSNotificationCenter defaultCenter] postNotificationName: ALFeatherConnectionInvalidatedNotification object: self];

}

#pragma mark -
#pragma mark Methods
#pragma mark -

- (id)remoteServerProxy
{

        ALAssertOrRaise(mValid);
        ALAssertOrRaise(mRemoteServerProxy);
    
    return mRemoteServerProxy;

}

- (void)handleIncomingRequestData: (NSData *)requestData
{

        NSParameterAssert(requestData && [requestData length]);
        ALAssertOrRaise(mValid);
    
    [mIncomingRequestData appendData: requestData];
    
    for (;;)
    {
    
        uint64_t requestHeader = 0;
        NSUInteger archivedRequestDataLength = 0;
        NSData *archivedRequestData = nil;
        NSDictionary *request = nil;
        BOOL enqueueIncomingRequestResult = NO;
        
            ALConfirmOrPerform([mIncomingRequestData length] >= sizeof(requestHeader), return);
        
        /* Attempt to form a full request from the accumulated data. */
        
        [mIncomingRequestData getBytes: &requestHeader length: sizeof(requestHeader)];
        
            /* Verify that archivedRequestDataLength can hold the host-endian requestHeader. */
            
            ALAssertOrPerform(ALIntValidValueForObject(CFSwapInt64LittleToHost(requestHeader), archivedRequestDataLength), goto failed);
        
        archivedRequestDataLength = CFSwapInt64LittleToHost(requestHeader);
        
            /* Verify that mIncomingRequestData contains the entire archived request's data. */
            
            ALConfirmOrPerform(([mIncomingRequestData length] - sizeof(requestHeader)) >= archivedRequestDataLength, return);
        
        archivedRequestData = [mIncomingRequestData subdataWithRange: NSMakeRange(sizeof(requestHeader), archivedRequestDataLength)];
        request = [NSKeyedUnarchiver unarchiveObjectWithData: archivedRequestData];
        
            ALAssertOrPerform(request && [request isKindOfClass: [NSDictionary class]], goto failed);
        
            /* Verify that archivedRequestDataLength + sizeof(requestHeader) won't wrap. */
            
            ALAssertOrPerform(archivedRequestDataLength <= (ALIntMaxValueForObject(NSUInteger) - sizeof(requestHeader)), goto failed);
        
        /* Update mIncomingRequestData before we callout. */
        
        [self setIncomingRequestData: [NSMutableData dataWithBytes: ([mIncomingRequestData bytes] + sizeof(requestHeader) + archivedRequestDataLength)
            length: ([mIncomingRequestData length] - (sizeof(requestHeader) + archivedRequestDataLength))]];
        
        /* Finally, enqueue our request! */
        
        enqueueIncomingRequestResult = [self enqueueIncomingRequest: request];
        
            ALAssertOrPerform(enqueueIncomingRequestResult, goto failed);
    
    }
    
    return;
    failed:
    {
    
        [self invalidate];
    
    }

}

- (NSString *)replyMode
{

    return ALUniqueStringForThisMethodAndInstance;

}

#pragma mark -
#pragma mark Subclass Methods
#pragma mark -

- (void)enqueueOutgoingRequestData: (NSData *)requestData
{

    [NSException raise: NSGenericException format: @""];

}

#pragma mark -
#pragma mark Private Methods
#pragma mark -

- (void)sendInvocation: (NSInvocation *)invocation
{

    NSMethodSignature *methodSignature = nil;
    NSUInteger argumentsCount = 0,
               currentArgumentIndex = 0;
    NSMutableArray *arguments = nil;
    NSMutableDictionary *request = nil;
    BOOL enqueueOutgoingRequestResult = NO;
    
        NSParameterAssert(invocation);
        ALAssertOrRaise(mValid);
    
    /* First we'll reset our flag telling whether our invocation succeeded. */
    
    mLastInvocationSucceeded = NO;
    
    /* And let's go! */
    
    methodSignature = [invocation methodSignature];
    
        ALAssertOrPerform(methodSignature, goto failed);
    
    argumentsCount = [methodSignature numberOfArguments];
    
        ALAssertOrPerform(argumentsCount >= 2, goto failed);
    
    arguments = [NSMutableArray array];
    
    /* Fill in the arguments by starting at index 2, which is the first actual argument (following self and _cmd.) */
    
    [arguments addObject: NSStringFromSelector([invocation selector])];
    for (currentArgumentIndex = 2; currentArgumentIndex < argumentsCount; currentArgumentIndex++)
    {
    
        const char *currentArgumentTypeString = nil;
        ALFeatherType currentArgumentType = ALFeatherTypeInit;
        ALFeatherArgument *currentFeatherArgument = nil;
        
        currentArgumentTypeString = [methodSignature getArgumentTypeAtIndex: currentArgumentIndex];
        
            ALAssertOrPerform(currentArgumentTypeString, goto failed);
        
        currentArgumentType = validateTypeString(currentArgumentTypeString, NO);
        
            /* Raising because it's programmer-error if the argument isn't a type that we support. */
            
            ALAssertOrRaise(ALFeatherTypeValid(currentArgumentType));
        
        if (currentArgumentType == ALFeatherTypeObject)
        {
        
            id <NSObject, NSCoding> objectValue = nil;
            
            [invocation getArgument: &objectValue atIndex: currentArgumentIndex];
            
                /* Raising because it's programmer error if the class doesn't conform to NSObject & NSCoding. */
                
                ALAssertOrRaise(!objectValue || ([objectValue conformsToProtocol: @protocol(NSObject)] && [objectValue conformsToProtocol: @protocol(NSCoding)]));
            
            currentFeatherArgument = [[[ALFeatherArgument alloc] initWithType: ALFeatherTypeObject value: &objectValue] autorelease];
        
        }
        
        else if (currentArgumentType == ALFeatherTypeInt64)
        {
        
            int64_t scalarValue = 0;
            
            [invocation getArgument: &scalarValue atIndex: currentArgumentIndex];
            currentFeatherArgument = [[[ALFeatherArgument alloc] initWithType: ALFeatherTypeInt64 value: &scalarValue] autorelease];
        
        }
        
        else if (currentArgumentType == ALFeatherTypeUInt64)
        {
        
            uint64_t scalarValue = 0;
            
            [invocation getArgument: &scalarValue atIndex: currentArgumentIndex];
            currentFeatherArgument = [[[ALFeatherArgument alloc] initWithType: ALFeatherTypeUInt64 value: &scalarValue] autorelease];
        
        }
        
        else if (currentArgumentType == ALFeatherTypeFloat64)
        {
        
            Float64 scalarValue = 0;
            
            [invocation getArgument: &scalarValue atIndex: currentArgumentIndex];
            currentFeatherArgument = [[[ALFeatherArgument alloc] initWithType: ALFeatherTypeFloat64 value: &scalarValue] autorelease];
        
        }
        
        [arguments addObject: currentFeatherArgument];
    
    }
    
    /* Enqueue our outgoing request. */
    
    request = [NSMutableDictionary dictionary];
    [request setObject: [NSNumber numberWithBool: YES] forKey: kRequestTypeKey];
    [request setObject: arguments forKey: kRequestArgumentsKey];
    
    if ([methodSignature isOneway])
        [request setObject: [NSNull null] forKey: kRequestOnewayKey];
    
    enqueueOutgoingRequestResult = [self enqueueOutgoingRequest: request];
    
        ALAssertOrPerform(enqueueOutgoingRequestResult, goto failed);
    
    /* If the method isn't oneway, then we'll await a reply. */
    
    if (![methodSignature isOneway])
    {
    
        NSDictionary *reply = nil;
        const char *returnValueTypeString = nil;
        ALFeatherType returnValueType = ALFeatherTypeInit;
        ALFeatherArgument *returnValue = nil;
        
        reply = [self waitForReply];
        
            ALAssertOrPerform(reply, goto failed);
            ALAssertOrPerform(![reply objectForKey: kRequestExceptionKey], goto failed);
        
        returnValueTypeString = [methodSignature methodReturnType];
        
            ALAssertOrPerform(returnValueTypeString, goto failed);
        
        returnValueType = validateTypeString(returnValueTypeString, YES);
        
            /* Raising because it's programmer-error if the return value isn't a type that we support. */
            
            ALAssertOrRaise(ALFeatherTypeValid(returnValueType));
        
        returnValue = [reply objectForKey: kRequestReturnValueKey];
        
            ALAssertOrPerform(returnValue, goto failed);
            ALAssertOrPerform([returnValue type] == returnValueType, goto failed);
        
        if (returnValueType == ALFeatherTypeObject)
        {
        
            id objectValue = nil;
            
            objectValue = [returnValue objectValue];
            [invocation setReturnValue: &objectValue];
        
        }
        
        else if (returnValueType == ALFeatherTypeInt64)
        {
        
            int64_t scalarValue = 0;
            
            scalarValue = [returnValue int64Value];
            [invocation setReturnValue: &scalarValue];
        
        }
        
        else if (returnValueType == ALFeatherTypeUInt64)
        {
        
            uint64_t scalarValue = 0;
            
            scalarValue = [returnValue uint64Value];
            [invocation setReturnValue: &scalarValue];
        
        }
        
        else if (returnValueType == ALFeatherTypeFloat64)
        {
        
            Float64 scalarValue = 0.0;
            
            scalarValue = [returnValue float64Value];
            [invocation setReturnValue: &scalarValue];
        
        }
    
    }
    
    mLastInvocationSucceeded = YES;
    return;
    
    failed:
    {
    
        [self invalidate];
    
    }

}

- (BOOL)enqueueIncomingRequest: (NSDictionary *)request
{

        NSParameterAssert(request);
        NSParameterAssert([request objectForKey: kRequestTypeKey]);
        ALAssertOrRaise(mValid);
    
    if ([[request objectForKey: kRequestTypeKey] boolValue])
    {
    
            /* We must have a server object if we have an incoming invocation request. */
            
            ALAssertOrPerform(mLocalServerObject, goto failed);
        
        if (mWaitingForReply)
        {
        
                /* We received an incoming invocation request, but we're currently waiting for a response. Therefore the
                   incoming invocation better we oneway! */
                
                ALAssertOrPerform([request objectForKey: kRequestOnewayKey], goto failed);
            
            /* Schedule the request to be handled on the next run loop iteration. */
            
            CFRunLoopPerformBlock(CFRunLoopGetCurrent(), NSRunLoopCommonModes,
            ^{
            
                if ([self valid])
                    [self enqueueIncomingRequest: request];
            
            });
            
            CFRunLoopWakeUp(CFRunLoopGetCurrent());
        
        }
        
        else
        {
        
            BOOL handleIncomingRequestResult = NO;
            
            handleIncomingRequestResult = [self handleIncomingRequest: request];
            
                ALAssertOrPerform(handleIncomingRequestResult, goto failed);
        
        }
    
    }
    
    else
    {
    
            /* We have an invocation reply, so we have better been expecting one! */
            
            ALAssertOrPerform(mWaitingForReply, goto failed);
        
        [self setReply: request];
        CFRunLoopStop(CFRunLoopGetCurrent());
    
    }
    
    return YES;
    
    failed:
    {
    }
    
    return NO;

}

- (BOOL)handleIncomingRequest: (NSDictionary *)request
{

    NSArray *arguments = nil;
    SEL selector = nil;
    NSMethodSignature *methodSignature = nil;
    NSMutableDictionary *reply = nil;
    
        NSParameterAssert(request);
        NSParameterAssert([request objectForKey: kRequestTypeKey]);
        NSParameterAssert([request objectForKey: kRequestArgumentsKey] && [[request objectForKey: kRequestArgumentsKey] count]);
        
        ALAssertOrRaise(mValid);
        ALAssertOrRaise(!mWaitingForReply);
        ALAssertOrRaise(mLocalServerObject);
    
    arguments = [request objectForKey: kRequestArgumentsKey];
    selector = NSSelectorFromString([arguments objectAtIndex: 0]);
    
        ALAssertOrPerform(selector, goto failed);
    
    methodSignature = [mLocalServerObject methodSignatureForSelector: selector];
    
        ALAssertOrPerform(methodSignature, goto failed);
        
        /* Verify that the local and remote ends agree on whether the call is oneway. */
        
        ALAssertOrPerform(ALEqualBools([methodSignature isOneway], [request objectForKey: kRequestOnewayKey]), goto failed);
    
    /* Start creating our reply. */
    
    reply = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: NO], kRequestTypeKey, nil];
    
        ALAssertOrPerform([mLocalServerObject respondsToSelector: selector], ALNoOp);
    
    if ([mLocalServerObject respondsToSelector: selector])
    {
    
        NSInvocation *invocation = nil;
        NSUInteger currentArgumentIndex = 2;
        BOOL exceptionOccurred = NO;
        
        invocation = [NSInvocation invocationWithMethodSignature: methodSignature];
        
            ALAssertOrPerform(invocation, goto failed);
        
        [invocation setTarget: mLocalServerObject];
        [invocation setSelector: selector];
        
        for (currentArgumentIndex = 2; currentArgumentIndex < [methodSignature numberOfArguments]; currentArgumentIndex++)
        {
        
            const char *currentArgumentTypeString = nil;
            ALFeatherType currentArgumentType = ALFeatherTypeInit;
            ALFeatherArgument *currentFeatherArgument = nil;
            
            currentArgumentTypeString = [methodSignature getArgumentTypeAtIndex: currentArgumentIndex];
            
                ALAssertOrPerform(currentArgumentTypeString, goto failed);
            
            currentArgumentType = validateTypeString(currentArgumentTypeString, NO);
            
                /* Raising because it's programmer-error if the argument isn't a type that we support. */
                
                ALAssertOrRaise(ALFeatherTypeValid(currentArgumentType));
            
            currentFeatherArgument = [arguments objectAtIndex: (currentArgumentIndex - 1)];
            
                ALAssertOrPerform(currentFeatherArgument, goto failed);
                ALAssertOrPerform([currentFeatherArgument isKindOfClass: [ALFeatherArgument class]], goto failed);
                ALAssertOrPerform([currentFeatherArgument type] == currentArgumentType, goto failed);
            
            if (currentArgumentType == ALFeatherTypeObject)
            {
            
                id objectValue = nil;
                
                objectValue = [currentFeatherArgument objectValue];
                [invocation setArgument: &objectValue atIndex: currentArgumentIndex];
            
            }
            
            else if (currentArgumentType == ALFeatherTypeInt64)
            {
            
                int64_t scalarValue = 0;
                
                scalarValue = [currentFeatherArgument int64Value];
                [invocation setArgument: &scalarValue atIndex: currentArgumentIndex];
            
            }
            
            else if (currentArgumentType == ALFeatherTypeUInt64)
            {
            
                uint64_t scalarValue = 0;
                
                scalarValue = [currentFeatherArgument uint64Value];
                [invocation setArgument: &scalarValue atIndex: currentArgumentIndex];
            
            }
            
            else if (currentArgumentType == ALFeatherTypeFloat64)
            {
            
                Float64 scalarValue = 0;
                
                scalarValue = [currentFeatherArgument float64Value];
                [invocation setArgument: &scalarValue atIndex: currentArgumentIndex];
            
            }
        
        }
        
        @try
        {
        
            [invocation invoke];
        
        }
        
        @catch(id exception)
        {
        
            [reply setObject: [NSNull null] forKey: kRequestExceptionKey];
            exceptionOccurred = YES;
        
        }
        
        /* If no exception was thrown and the method isn't oneway, then we'll handle the method's return value. */
        
        if (!exceptionOccurred && ![methodSignature isOneway])
        {
        
            const char *returnValueTypeString = nil;
            ALFeatherType returnValueType = ALFeatherTypeInit;
            ALFeatherArgument *returnValue = nil;
            
            returnValueTypeString = [methodSignature methodReturnType];
            
                ALAssertOrPerform(returnValueTypeString, goto failed);
            
            returnValueType = validateTypeString(returnValueTypeString, YES);
            
                /* Raising because it's programmer-error if the return value isn't a type that we support. */
                
                ALAssertOrRaise(ALFeatherTypeValid(returnValueType));
            
            if (returnValueType == ALFeatherTypeVoid)
                returnValue = [[[ALFeatherArgument alloc] initWithType: ALFeatherTypeVoid value: nil] autorelease];
            
            else if (returnValueType == ALFeatherTypeObject)
            {
            
                id <NSObject, NSCoding> objectValue = nil;
                
                [invocation getReturnValue: &objectValue];
                
                    /* Raising because it's programmer error if the class doesn't conform to NSObject & NSCoding. */
                    
                    ALAssertOrRaise(!objectValue || ([objectValue conformsToProtocol: @protocol(NSObject)] && [objectValue conformsToProtocol: @protocol(NSCoding)]));
                
                returnValue = [[[ALFeatherArgument alloc] initWithType: ALFeatherTypeObject value: &objectValue] autorelease];
            
            }
            
            else if (returnValueType == ALFeatherTypeInt64)
            {
            
                int64_t scalarValue = 0;
                
                [invocation getReturnValue: &scalarValue];
                returnValue = [[[ALFeatherArgument alloc] initWithType: ALFeatherTypeInt64 value: &scalarValue] autorelease];
            
            }
            
            else if (returnValueType == ALFeatherTypeUInt64)
            {
            
                uint64_t scalarValue = 0;
                
                [invocation getReturnValue: &scalarValue];
                returnValue = [[[ALFeatherArgument alloc] initWithType: ALFeatherTypeUInt64 value: &scalarValue] autorelease];
            
            }
            
            else if (returnValueType == ALFeatherTypeFloat64)
            {
            
                Float64 scalarValue = 0;
                
                [invocation getReturnValue: &scalarValue];
                returnValue = [[[ALFeatherArgument alloc] initWithType: ALFeatherTypeFloat64 value: &scalarValue] autorelease];
            
            }
            
            [reply setObject: returnValue forKey: kRequestReturnValueKey];
        
        }
    
    }
    
    else
    {
    
        /* The local server object doesn't respond to the given selector. */
        
        [reply setObject: [NSNull null] forKey: kRequestExceptionKey];
    
    }
    
    /* We're not sending a reply if the invocation is oneway. */
    
    if (![methodSignature isOneway])
        [self enqueueOutgoingRequest: reply];
    
    return YES;
    
    failed:
    {
    }
    
    return NO;

}

- (BOOL)enqueueOutgoingRequest: (NSDictionary *)request
{

    NSData *archivedRequestData = nil;
    NSUInteger archivedRequestDataLength = 0;
    uint64_t requestHeader = 0;
    NSMutableData *requestData = nil;
    
        NSParameterAssert(request);
    
    archivedRequestData = [NSKeyedArchiver archivedDataWithRootObject: request];
    
        /* We don't necessarily know that [archivedRequestData length] will necessarily be > 0, so we're not checking for that. */
        
        ALAssertOrPerform(archivedRequestData, goto failed);
    
    archivedRequestDataLength = [archivedRequestData length];
    
        /* Verify that archivedRequestDataLength can be safely converted to uint64_t as an argument to CFSwapInt64HostToLittle(). */
        
        ALAssertOrPerform(ALIntValidValueForObject(archivedRequestDataLength, uint64_t), goto failed);
    
    requestHeader = CFSwapInt64HostToLittle(archivedRequestDataLength);
    
    /* Finally, create our request data to send to the remote end. */
    
    requestData = [NSMutableData data];
    [requestData appendBytes: &requestHeader length: sizeof(requestHeader)];
    [requestData appendData: archivedRequestData];
    [self enqueueOutgoingRequestData: requestData];
    
    return YES;
    
    failed:
    {
    }
    
    return NO;

}

- (NSDictionary *)waitForReply
{

    [self setReply: nil];
    mWaitingForReply = YES;
    
    do [[NSRunLoop currentRunLoop] guaranteedRunMode: [self replyMode] timeout: INFINITY returnAfterSourceHandled: NO];
    while (mValid && !mReply);
    
    mWaitingForReply = NO;
    return mReply;

}

@end

@implementation ALFeatherProxy
@synthesize connection = mConnection;

- (id)init
{

    /* Super doesn't implement -init; we're just defining this method so ALFeatherProxy can be instantiated with the
       usual -alloc, -init pattern. */
    
    return self;

}

#pragma mark -
#pragma mark Override Methods
#pragma mark -

- (void)forwardInvocation: (NSInvocation *)invocation
{

        NSParameterAssert(invocation);
        ALAssertOrRaise(mConnection);
    
    [mConnection sendInvocation: invocation];

}

- (NSMethodSignature *)methodSignatureForSelector: (SEL)selector
{

    struct objc_method_description methodDescription;
    
        NSParameterAssert(selector);
        ALAssertOrRaise(mConnection);
    
    methodDescription = protocol_getMethodDescription([mConnection remoteServerProtocol], selector, YES, YES);
    
        ALAssertOrPerform(methodDescription.name && methodDescription.types, return nil);
    
    return [NSMethodSignature signatureWithObjCTypes: methodDescription.types];

}

@end

@implementation ALFeatherArgument

static ALStringConst(kTypeKey);
static ALStringConst(kObjectValueKey);
static ALStringConst(kScalarValueKey);

@synthesize type = mType;
@synthesize objectValue = mObjectValue;
@synthesize scalarValue = mScalarValue;

#pragma mark -
#pragma mark Creation
#pragma mark -

- (id)initWithType: (ALFeatherType)type value: (void *)value
{

        NSParameterAssert(ALFeatherTypeValid(type));
        NSParameterAssert(type == ALFeatherTypeVoid || value);
    
    if (!(self = [super init]))
        return nil;
    
    [self setType: type];
    
    if (mType == ALFeatherTypeObject)
    {
    
            /* Verify that the given object is either nil, or is an object that conforms to the NSObject and NSCoding protocols. */
            
            NSParameterAssert(!*((id *)value) || ([*((id *)value) conformsToProtocol: @protocol(NSObject)] && [*((id *)value) conformsToProtocol: @protocol(NSCoding)]));
        
        [self setObjectValue: *((id *)value)];
    
    }
    
    else if (mType == ALFeatherTypeInt64 || mType == ALFeatherTypeUInt64 || mType == ALFeatherTypeFloat64)
        memcpy(&mScalarValue, value, sizeof(mScalarValue));
    
    return self;

}

- (void)dealloc
{

    [self setObjectValue: nil];
    [super dealloc];

}

- (id)initWithCoder: (NSCoder *)coder
{

    const uint8_t *decodedBytes = nil;
    NSUInteger decodedBytesLength = 0;
    
        /* We only support keyed coding. */
        
        NSParameterAssert([coder allowsKeyedCoding]);
        
    /* First we'll decode our type. */
    
        ALAssertOrPerform([coder containsValueForKey: kTypeKey], goto failed);
    
    decodedBytes = [coder decodeBytesForKey: kTypeKey returnedLength: &decodedBytesLength];
    
        ALAssertOrPerform(decodedBytes, goto failed);
        ALAssertOrPerform(decodedBytesLength == sizeof(mType), goto failed);
    
    memcpy(&mType, decodedBytes, sizeof(mType));
    
        #warning debug; we're debugging the assertion that failed below by halting and waiting the debugger to attach!
        int a = 1;
        ALAssertOrPerform(ALFeatherTypeValid(mType), while (a); goto failed);
    
    if (mType == ALFeatherTypeObject)
    {
    
            /* Works even when the encoded object was nil. */
            
            ALAssertOrPerform([coder containsValueForKey: kObjectValueKey], goto failed);
        
        [self setObjectValue: [coder decodeObjectForKey: kObjectValueKey]];
    
    }
    
    else if (mType == ALFeatherTypeInt64 || mType == ALFeatherTypeUInt64)
    {
    
        uint64_t decodedValue = 0;
        
            ALAssertOrPerform([coder containsValueForKey: kScalarValueKey], goto failed);
        
        decodedBytes = [coder decodeBytesForKey: kScalarValueKey returnedLength: &decodedBytesLength];
        
            ALAssertOrPerform(decodedBytes, goto failed);
            ALAssertOrPerform(decodedBytesLength == sizeof(decodedValue), goto failed);
        
        decodedValue = CFSwapInt64LittleToHost(*((uint64_t *)decodedBytes));
        memcpy(&mScalarValue, &decodedValue, sizeof(mScalarValue));
    
    }
    
    else if (mType == ALFeatherTypeFloat64)
    {
    
        Float64 decodedValue;
        
            ALAssertOrPerform([coder containsValueForKey: kScalarValueKey], goto failed);
        
        decodedBytes = [coder decodeBytesForKey: kScalarValueKey returnedLength: &decodedBytesLength];
        
            ALAssertOrPerform(decodedBytes, goto failed);
            ALAssertOrPerform(decodedBytesLength == sizeof(decodedValue), goto failed);
        
        decodedValue = CFConvertFloat64SwappedToHost(*((CFSwappedFloat64 *)decodedBytes));
        memcpy(&mScalarValue, &decodedValue, sizeof(mScalarValue));
    
    }
    
    return self;
    
    failed:
    {
    
        [self release];
    
    }
    
    return nil;

}

- (void)encodeWithCoder: (NSCoder *)coder
{

        /* We only support keyed coding. */
        
        NSParameterAssert([coder allowsKeyedCoding]);
    
    [coder encodeBytes: &mType length: sizeof(mType) forKey: kTypeKey];
    
    if (mType == ALFeatherTypeObject)
        [coder encodeObject: [self objectValue] forKey: kObjectValueKey];
    
    else if (mType == ALFeatherTypeInt64)
    {
    
        int64_t value = 0;
        uint64_t encodedValue = 0;
        
        value = [self int64Value];
        encodedValue = CFSwapInt64HostToLittle(*((uint64_t *)&value));
        [coder encodeBytes: (uint8_t *)&encodedValue length: sizeof(encodedValue) forKey: kScalarValueKey];
    
    }
    
    else if (mType == ALFeatherTypeUInt64)
    {
    
        uint64_t encodedValue = 0;
        
        encodedValue = CFSwapInt64HostToLittle([self uint64Value]);
        [coder encodeBytes: (uint8_t *)&encodedValue length: sizeof(encodedValue) forKey: kScalarValueKey];
    
    }
    
    else if (mType == ALFeatherTypeFloat64)
    {
    
        CFSwappedFloat64 encodedValue;
        
        encodedValue = CFConvertFloat64HostToSwapped([self float64Value]);
        [coder encodeBytes: (uint8_t *)&encodedValue length: sizeof(encodedValue) forKey: kScalarValueKey];
    
    }

}

#pragma mark -
#pragma mark Methods
#pragma mark -

- (id)objectValue
{

        ALAssertOrRaise(mType == ALFeatherTypeObject);
    
    return mObjectValue;

}

- (int64_t)int64Value
{

        ALAssertOrRaise(mType == ALFeatherTypeInt64);
    
    return *((int64_t *)&mScalarValue);

}

- (uint64_t)uint64Value
{

        ALAssertOrRaise(mType == ALFeatherTypeUInt64);
    
    return *((uint64_t *)&mScalarValue);

}

- (Float64)float64Value
{

        ALAssertOrRaise(mType == ALFeatherTypeFloat64);
    
    return *((Float64 *)&mScalarValue);

}

@end