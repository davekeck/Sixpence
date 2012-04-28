#import "ALAnimationTimer.h"

#pragma mark Property Redeclarations
#pragma mark -

@interface ALAnimationTimer ()

@property(nonatomic, readwrite, retain) id userInfo1;
@property(nonatomic, readwrite, retain) id userInfo2;

@end

#pragma mark -
#pragma mark Class Implementations
#pragma mark -

@implementation ALAnimationTimer

#pragma mark -
#pragma mark Creation
#pragma mark -

- (id)initWithDuration: (NSTimeInterval)newDuration animationCurve: (NSAnimationCurve)newAnimationCurve
    userInfo1: (id)newUserInfo1 userInfo2: (id)newUserInfo2 delegate: (id)newDelegate
{

        NSParameterAssert(newDelegate);
    
    if (!(self = [super initWithDuration: newDuration animationCurve: newAnimationCurve]))
        return nil;
    
    [self setUserInfo1: newUserInfo1];
    [self setUserInfo2: newUserInfo2];
    [self setDelegate: newDelegate];
    
    return self;

}

- (void)dealloc
{

    [self setUserInfo1: nil];
    [self setUserInfo2: nil];
    [super dealloc];

}

#pragma mark -
#pragma mark Properties

@synthesize userInfo1;
@synthesize userInfo2;

#pragma mark -
#pragma mark Override Methods
#pragma mark -

- (void)setCurrentProgress: (NSAnimationProgress)progress
{

    id delegate = nil;
    
    delegate = [self delegate];
    
    [super setCurrentProgress: progress];
    
    if (delegate && [delegate respondsToSelector: @selector(animationTimer: didReachValue:)])
        [delegate animationTimer: self didReachValue: ALCapRange([super currentValue], 0.0, 1.0)];

}

@end