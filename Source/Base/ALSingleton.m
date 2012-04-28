#import "ALSingleton.h"

#pragma mark Class Implementations
#pragma mark -

@implementation ALSingleton

#pragma mark Globals
#pragma mark -

static CFMutableDictionaryRef gEntries = nil;

#pragma mark -
#pragma mark Creation
#pragma mark -

+ (void)initialize
{

        /* Because a class' +initialize method can be called more than once, we need to make
           sure it's being called for us, specifically. */
        
        ALConfirmOrPerform(self == [ALSingleton class], return);
    
    /* Note that we're creating and using a CFDictionary, not an NSDictionary. This is because the NS-CF dictionaries
       don't have the same behavior regarding weak keys and values, even with toll-free bridging. See:
       
       http://lists.apple.com/archives/cocoa-dev/2011/Jul/msg00216.html */
    
    gEntries = CFDictionaryCreateMutable(nil, 0x10, nil, &kCFTypeDictionaryValueCallBacks);

}

+ (id)sharedInstance
{

    return [self sharedInstanceForClass: self];

}

+ (id)sharedInstanceForClass: (Class)class
{

    id result = nil;
    
    @synchronized((id)gEntries)
    {
    
        result = (id)CFDictionaryGetValue(gEntries, class);
        
        if (!result)
        {
        
            result = [[[class alloc] initSingleton] autorelease];
            
            if (result)
                CFDictionarySetValue(gEntries, class, result);
        
        }
    
    }
    
    return result;

}

- (id)init
{

    /* Here we'll simply return the object that would have been supplied if the caller invoked [ReceiverClass sharedInstance]. */
    
        /* Verify that -init hasn't been overridden by a subclass (ALSingleton subclasses must use -initSingleton.) */
        
        ALAssertOrRaise([ALSingleton instanceMethodForSelector: @selector(init)] == [[self class] instanceMethodForSelector: @selector(init)]);
    
    /* Autorelease instead of release so that we can ask for its -class safely. */
    
    [self autorelease];
    return [[[self class] sharedInstance] retain];

}

- (id)initSingleton
{

    if (!(self = [super init]))
        return nil;
    
    return self;

}

@end