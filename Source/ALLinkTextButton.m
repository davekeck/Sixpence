// Garbage Collection
//   o finalize not necessary

#import "ALLinkTextButton.h"

#pragma mark Class Implementations
#pragma mark -

@implementation ALLinkTextButton

#pragma mark -
#pragma mark Creation
#pragma mark -

- (void)dealloc
{

    [self setURL: nil];
    [super dealloc];

}

#pragma mark -
#pragma mark Public Properties
#pragma mark -

@synthesize url;

- (void)setURL: (NSURL *)newURL
{

        ALAssertOrRaise((!initialized && newURL) || !newURL);
    
    if (newURL)
    {
    
        NSDictionary *currentAttributes = nil;
        NSMutableDictionary *attributes = nil;
        NSAttributedString *attributedString = nil;
        
        /* First, set our text's attributes. */
        
        currentAttributes = [[self attributedTitle] attributesAtIndex: 0 effectiveRange: nil];
        
        attributes = [NSMutableDictionary dictionary];
        if (currentAttributes) [attributes addEntriesFromDictionary: currentAttributes];
        [attributes setObject: [NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0] forKey: NSForegroundColorAttributeName];
        [attributes setObject: [NSNumber numberWithInteger: NSSingleUnderlineStyle] forKey: NSUnderlineStyleAttributeName];
        
        attributedString = [[[NSAttributedString alloc] initWithString: [self title] attributes: attributes] autorelease];
        [self setAttributedTitle: attributedString];
        
        [self setTarget: self];
        [self setAction: @selector(performClick:)];
        
        /* Next, set up our tracking area so that the hand cursor appears when the mouse is over the link. */
        
        [[self window] invalidateCursorRectsForView: self];
        
        /* Keep our URL around. */
        
        [newURL retain];
        [url release];
        url = newURL;
        
        /* Mark ourself as initialized. Note that once we're initialized, the URL can't be changed (ie, the URL can only be set once.) */
        
        initialized = YES;
    
    }
    
    else
    {
    
        /* Reset our URL. */
        
        [url release],
        url = nil;
        
        /* ### Note that we're _not_ resetting our initialized variable. Once it's set to YES, it can't be unset. This is what prevents
               us from setting our URL more than once (which we don't allow.) */
    
    }

}

#pragma mark -
#pragma mark Override Methods
#pragma mark -

- (void)resetCursorRects
{

    [self addCursorRect: [self bounds] cursor: [NSCursor pointingHandCursor]];

}

- (void)performClick: (id)sender
{

    if (url)
        [[NSWorkspace sharedWorkspace] openURL: url];

}

@end