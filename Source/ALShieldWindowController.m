#warning the shield window doesn't seem to be updating when a new display is plugged-in while the computer is asleep, and then the computer is woken up
#warning we might want to use CGDisplayRegisterReconfigurationCallback() to get notified of this situation? otherwise we may just need to update the
#warning shield window every time when we wake from sleep

#import "ALShieldWindowController.h"

#import "NSScreen+AllScreensFrame.h"

#pragma mark Property Redeclarations
#pragma mark -

@interface ALShieldWindowController ()

@property(nonatomic, readwrite, retain) NSWindow *shieldWindow;

@end

#pragma mark -
#pragma mark Private Method Interfaces
#pragma mark -

@interface ALShieldWindowController (Private)

#pragma mark -

- (void)updateShieldWindowFrame;

@end

#pragma mark -
#pragma mark Class Implementations
#pragma mark -

@implementation ALShieldWindowController

#pragma mark -
#pragma mark Creation
#pragma mark -

- (id)initSingleton
{

    if (!(self = [super initSingleton]))
        goto failed;
    
    [self setShieldWindow: [[[NSWindow alloc] initWithContentRect: NSMakeRect(0.0, 0.0, 1.0, 1.0)
        styleMask: NSBorderlessWindowMask backing: NSBackingStoreBuffered defer: NO] autorelease]];
    
        ALAssertOrPerform(shieldWindow, goto failed);
    
    [shieldWindow setBackgroundColor: [NSColor blackColor]];
    
    /* This is required to prevent the window from being over-released, and thus crashing the app when it's referenced after being closed. */
    
    [shieldWindow setReleasedWhenClosed: NO];
    
    /* Update the shield window's frame now that it's all allocated n sheeeit. */
    
    [self updateShieldWindowFrame];
    
    /* We want to know when the screen configuration changes so we can update the shield window's frame, and notify our delegate. */
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(receivedApplicationDidChangeScreenParametersNotification:)
        name: NSApplicationDidChangeScreenParametersNotification object: nil];
    
    return self;
    
    failed:
    {
    
        [self release];
    
    }
    
    return nil;

}

#pragma mark -
#pragma mark Properties

@synthesize shieldWindow;
@synthesize delegate;

#pragma mark -
#pragma mark Notification Methods
#pragma mark -

- (void)receivedApplicationDidChangeScreenParametersNotification: (NSNotification *)notification
{

    /* Update the shield window's frame. */
    
    [self updateShieldWindowFrame];
    
    if (delegate && [delegate respondsToSelector: @selector(shieldWindowControllerDidUpdateShieldWindowFrame:)])
        [delegate shieldWindowControllerDidUpdateShieldWindowFrame: self];

}

#pragma mark -
#pragma mark Private Methods
#pragma mark -

- (void)updateShieldWindowFrame
{

    [shieldWindow setFrame: [NSScreen allScreensFrame] display: YES];

}

@end