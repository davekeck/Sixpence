#import <Cocoa/Cocoa.h>

/* Class Interfaces */

@interface ALShieldWindowController : ALSingleton
{

@private
    
    NSWindow *shieldWindow;
    __weak id delegate;

}

/* Properties */

@property(nonatomic, readonly, retain) NSWindow *shieldWindow;
@property(nonatomic, assign) __weak id delegate;

@end

@interface NSObject (ALShieldWindowController_Delegate)

- (void)shieldWindowControllerDidUpdateShieldWindowFrame: (ALShieldWindowController *)sender;

@end