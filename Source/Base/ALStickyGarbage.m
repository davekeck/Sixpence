//#warning we can drop this class once GC supports interior pointers

#import "ALStickyGarbage.h"

#import <pthread.h>

#pragma mark Class Implementations
#pragma mark -

@implementation ALStickyGarbage

#pragma mark -
#pragma mark Static Variables
#pragma mark -

static pthread_key_t gThreadStickyGarbageKey = 0;

#pragma mark Private Function Interfaces
#pragma mark -

static void threadExitDestructorCallback(void *info);

#pragma mark -
#pragma mark Creation
#pragma mark -

+ (void)initialize
{

    int pthreadResult = 0;
    
        /* Because a class' +initialize method can be called more than once, we need to make
           sure it's being called for us, specifically. */
        
        ALConfirmOrPerform(self == [ALStickyGarbage class], return);
        ALConfirmOrPerform([NSGarbageCollector defaultCollector], return);
    
    pthreadResult = pthread_key_create(&gThreadStickyGarbageKey, threadExitDestructorCallback);
    
        ALAssertOrPerform(!pthreadResult, return);

}

+ (ALStickyGarbage *)currentStickyGarbage
{

    int pthreadResult = 0;
    ALStickyGarbage *result = nil;
    
        ALConfirmOrPerform([NSGarbageCollector defaultCollector], return nil);
    
    @synchronized(self)
    {
    
        result = pthread_getspecific(gThreadStickyGarbageKey);
        
        if (!result)
        {
        
            /* This is fancy because we're storing our reference to the new ALStickyGarbage instance with pthreads, so no one else is going to retain it. Since
               we're working under GC, the pthreads references aren't scanned, so we need the -superRetain to prevent it from being collected. Technically we
               don't need the autorelease bit since this is never reached unless we're running with GC enabled, but I'm used to writing GC-supported code. */
            
            result = [[[[ALStickyGarbage alloc] init] autorelease] superRetain];
            
            pthreadResult = pthread_setspecific(gThreadStickyGarbageKey, result);
            
                ALAssertOrPerform(!pthreadResult, return nil);
        
        }
    
    }
    
    return result;

}

- (id)init
{

    if (!(self = [super init]))
        return nil;
    
    pointers = [[NSPointerArray alloc] initWithPointerFunctions:
        [NSPointerFunctions pointerFunctionsWithOptions: (NSPointerFunctionsStrongMemory | NSPointerFunctionsOpaquePersonality)]];
    
    return self;

}

- (void)dealloc
{

    /* Technically this method will never be called since we don't allow instances of ALStickyGarbage to be created unless we're running under GC. */
    
    [self dumpStickyGarbage];
    
    if (pointers)
        [pointers release],
        pointers = nil;
    
    [super dealloc];

}

#pragma mark -
#pragma mark Notification Methods
#pragma mark -

- (void)dumpStickyGarbageTimerDidFire: (NSTimer *)sender
{

        NSParameterAssert(sender && sender == dumpStickyGarbageTimer);
    
    [self dumpStickyGarbage];

}

#pragma mark -
#pragma mark Methods
#pragma mark -

- (void)markStickyGarbage: (const void *__strong)pointer
{

        NSParameterAssert(pointer);
    
    /* Make our pointer stick around for a bit by adding it to our rooted pointer array. */
    
    [pointers addPointer: (void *)pointer];
    
    if (!dumpStickyGarbageTimer)
        ALSetTimer(&dumpStickyGarbageTimer, [NSTimer scheduledTimerWithTimeInterval: 0.0 target: self
            selector: @selector(dumpStickyGarbageTimerDidFire:) userInfo: nil repeats: NO]);

}

- (void)dumpStickyGarbage
{

    /* Smells nasty in hur! */
    
    ALSetTimer(&dumpStickyGarbageTimer, nil);
    [pointers setCount: 0];

}

#pragma mark -
#pragma mark Private Function Implementations
#pragma mark -

static void threadExitDestructorCallback(void *info)
{

    ALStickyGarbage *threadStickyGarbage = nil;
    
        NSCParameterAssert(info);
    
    threadStickyGarbage = info;
    
    [threadStickyGarbage dumpStickyGarbage];
    
    /* Balance the -superRetain that occurred in +currentStickyGarbage. */
    
    [threadStickyGarbage superRelease],
    threadStickyGarbage = nil;

}

@end