#import <Cocoa/Cocoa.h>

@interface ALAnimationTimer : NSAnimation
{

@private
    
    id userInfo1;
    id userInfo2;

}

/* Creation */

- (id)initWithDuration: (NSTimeInterval)newDuration animationCurve: (NSAnimationCurve)newAnimationCurve
    userInfo1: (id)newUserInfo1 userInfo2: (id)newUserInfo2 delegate: (id)newDelegate;

/* Properties */

@property(nonatomic, readonly, retain) id userInfo1;
@property(nonatomic, readonly, retain) id userInfo2;

@end

/* Delegate Methods */

@interface NSObject (ALAnimationTimer_Delegate)

- (void)animationTimer: (ALAnimationTimer *)sender didReachValue: (float)value;

@end