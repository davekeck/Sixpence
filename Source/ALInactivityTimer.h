#import <Cocoa/Cocoa.h>

/* Forward Declarations */

@class ALInactivityTimer;

/* Protocols */

@protocol ALInactivityTimer_Target
@required

- (void)inactivityTimerFired: (ALInactivityTimer *)sender;

@end

/* Class Interfaces */

@interface ALInactivityTimer : NSObject
{

@private
    
    id <ALInactivityTimer_Target> target;
    NSTimeInterval idleTime;
    BOOL running;
    NSTimer *checkIdleTimeTimer;

}

/* Creation */

- (id)initWithTarget: (id)newTarget idleTime: (NSTimeInterval)newIdleTime;

/* Properties */

@property(nonatomic, readonly, retain) id target;
@property(nonatomic, readonly, assign) NSTimeInterval idleTime;
@property(nonatomic, assign) BOOL running;

@end