#import "ALUserSessionInterface.h"

#import <utmpx.h>

#import <SystemConfiguration/SystemConfiguration.h>

#pragma mark Class Implementations
#pragma mark -

@implementation ALUserSessionInterface

static void activeUserChangedCallback(SCDynamicStoreRef	store, CFArrayRef changedKeys, void *info);

- (id)initSingleton
{

    SCDynamicStoreRef dynamicStore = nil;
    NSString *key = nil;
    BOOL setNotificationKeysResult = NO;
    CFRunLoopSourceRef runLoopSource = nil;
    
    if (!(self = [super initSingleton]))
        return nil;
    
    dynamicStore = (SCDynamicStoreRef)[[(id)SCDynamicStoreCreate(nil, (CFStringRef)ALUniqueStringForThisMethod, activeUserChangedCallback, nil) superAutorelease] retain];
    
        ALAssertOrPerform(dynamicStore, goto failed);
    
    key = [(id)SCDynamicStoreKeyCreateConsoleUser(nil) superAutorelease];
    
        ALAssertOrPerform(key, goto failed);
    
    setNotificationKeysResult = SCDynamicStoreSetNotificationKeys(dynamicStore, (CFArrayRef)[NSArray arrayWithObject: key], nil);
    
        ALAssertOrPerform(setNotificationKeysResult, goto failed);
    
    runLoopSource = (CFRunLoopSourceRef)[(id)SCDynamicStoreCreateRunLoopSource(nil, dynamicStore, 0) superAutorelease];
    
        ALAssertOrPerform(runLoopSource, goto failed);
    
    /* PNR */
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CFRunLoopWakeUp(CFRunLoopGetCurrent());
    
    return self;
    failed:
    {
    
        CFRunLoopSourceInvalidate(runLoopSource);
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
        
        [(id)dynamicStore release],
        dynamicStore = nil;
        
        [self release];
        return nil;
    
    }

}

#pragma mark -
#pragma mark Properties
#pragma mark -

@dynamic activeUserChangedNotification;

- (NSString *)activeUserChangedNotification
{

    return ALUniqueStringForThisMethod;

}

#pragma mark -
#pragma mark Methods
#pragma mark -

- (NSSet *)userNamesForExistingUserSessions
{

    struct utmpx *currentEntry = nil;
    NSMutableSet *result = nil;
    
    result = [NSMutableSet set];
    
    /* This will reset our state so getutxent starts from the beginning  */
    
    setutxent();
    
    while ((currentEntry = getutxent()))
    {
    
        /* Verify that we have a user and that currentEntry's session is a GUI ('console') session */
        
        if (currentEntry->ut_type == USER_PROCESS && strlen(currentEntry->ut_user) && !strcmp(currentEntry->ut_line, "console"))
            [result addObject: [NSString stringWithUTF8String: currentEntry->ut_user]];
    
    }
    
    endutxent();
    
    return result;

}

- (NSString *)userNameForActiveUserSession
{

    static NSString *const kLoginwindowUserName = @"loginwindow";
    NSString *result = nil;
    
    result = [(id)SCDynamicStoreCopyConsoleUser(nil, nil, nil) superAutorelease];
    
    if ([result isEqualToString: kLoginwindowUserName])
        result = nil;
    
    return result;

}

static void activeUserChangedCallback(SCDynamicStoreRef	store, CFArrayRef changedKeys, void *info)
{

    [[NSNotificationCenter defaultCenter] postNotificationName: [[ALUserSessionInterface sharedInstance] activeUserChangedNotification] object: nil];

}

@end