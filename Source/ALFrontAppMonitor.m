#import "ALFrontAppMonitor.h"

#import <Carbon/Carbon.h>

/* This has to be defined because the headers leave it out for 64-bit. */

extern EventTargetRef GetApplicationEventTarget();

#pragma mark -
#pragma mark ALFrontAppMonitor
#pragma mark -

@implementation ALFrontAppMonitor

#pragma mark -
#pragma mark Function Interfaces
#pragma mark -

static OSStatus frontAppDidSwitchCallback(EventHandlerCallRef handler, EventRef event, void *info);

#pragma mark -
#pragma mark Creation
#pragma mark -

- (id)initSingleton
{

    static const EventTypeSpec kFrontAppDidSwitchEventType = {kEventClassApplication, kEventAppFrontSwitched};
    OSStatus installApplicationEventHandlerResult = 0;
    
    if (!(self = [super initSingleton]))
        return nil;
    
    installApplicationEventHandlerResult = InstallApplicationEventHandler(frontAppDidSwitchCallback, 1, &kFrontAppDidSwitchEventType, nil, nil);
    
        ALAssertOrRaise(installApplicationEventHandlerResult == noErr);
    
    return self;

}

#pragma mark -
#pragma mark Methods
#pragma mark -

- (NSString *)frontAppDidSwitchNotificationName
{

    return ALUniqueStringForThisMethod;

}

#pragma mark -
#pragma mark Function Implementations
#pragma mark -

static OSStatus frontAppDidSwitchCallback(EventHandlerCallRef handler, EventRef event, void *info)
{

    [[[NSWorkspace sharedWorkspace] notificationCenter] postNotificationName: [[ALFrontAppMonitor sharedInstance] frontAppDidSwitchNotificationName] object: nil];
    
    return noErr;

}

@end