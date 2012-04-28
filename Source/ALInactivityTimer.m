#import "ALInactivityTimer.h"

#pragma mark -
#pragma mark Property Redeclarations
#pragma mark -

@interface ALInactivityTimer ()

@property(nonatomic, readwrite, retain) id target;
@property(nonatomic, readwrite, assign) NSTimeInterval idleTime;

@end

#pragma mark -
#pragma mark Private Method Interfaces
#pragma mark -

@interface ALInactivityTimer (Private)

- (void)checkIdleTime: (NSTimer *)sender;
- (void)setCheckIdleTimeTimer: (NSTimer *)newCheckIdleTimeTimer;

@end

#pragma mark -
#pragma mark Class Implementations
#pragma mark -

@implementation ALInactivityTimer

#pragma mark -
#pragma mark Creation
#pragma mark -

- (id)initWithTarget: (id)newTarget idleTime: (NSTimeInterval)newIdleTime
{

        NSParameterAssert(newTarget);
        NSParameterAssert(newIdleTime >= 0.0);
    
    if (!(self = [super init]))
        return nil;
    
    [self setTarget: newTarget];
    [self setIdleTime: newIdleTime];
    
    return self;

}

- (void)dealloc
{

    [self setTarget: nil];
    [super dealloc];

}

#pragma mark -
#pragma mark Properties
#pragma mark -

@synthesize target;
@synthesize idleTime;
@synthesize running;

- (void)setRunning: (BOOL)newRunning
{

        ALConfirmOrPerform(!ALEqualBools(running, newRunning), return);
    
    running = newRunning;
    
    if (running)
    {
    
        [self superRetain];
        [self checkIdleTime: nil];
    
    }
    
    else
    {
    
        [self setCheckIdleTimeTimer: nil];
        [self superRelease];
    
    }

}

#pragma mark -
#pragma mark Private Methods
#pragma mark -

- (void)checkIdleTime: (NSTimer *)sender
{

    CFTimeInterval currentIdleTime = 0.0;
    
    currentIdleTime = CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState, kCGAnyInputEventType);
    
        ALAssertOrPerform(currentIdleTime >= 0.0, return);
    
    if (currentIdleTime < idleTime)
    {
    
        [self setCheckIdleTimeTimer: [NSTimer scheduledTimerWithTimeInterval: ALCapMin((idleTime - currentIdleTime), 0.0)
            target: self selector: @selector(checkIdleTime:) userInfo: nil repeats: NO]];
    
    }
    
    else
    {
    
        [[self retain] autorelease];
        [self setRunning: NO];
        [target inactivityTimerFired: self];
    
    }

}

- (void)setCheckIdleTimeTimer: (NSTimer *)newCheckIdleTimeTimer
{

        ALConfirmOrPerform(checkIdleTimeTimer != newCheckIdleTimeTimer, return);
    
    [newCheckIdleTimeTimer retain];
    [checkIdleTimeTimer invalidate];
    [checkIdleTimeTimer release];
    checkIdleTimeTimer = newCheckIdleTimeTimer;

}

@end