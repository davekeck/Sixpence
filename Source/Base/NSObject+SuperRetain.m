#import "NSObject+SuperRetain.h"

/* The docs suggest using NSMakeCollectable() instead of CFRelease when running under GC:
   
   http://developer.apple.com/mac/library/documentation/cocoa/Conceptual/GarbageCollection/Articles/gcFinalize.html
     
   "You should typically use NSMakeCollectable() on Core Foundation objects rather than relying on CFRelease() in finalize—this
   way collectable Core Foundation objects are actually collected sooner." */

/* Necessary to silence warnings on platforms that don't define NSGarbageCollector. */

@interface NSObject (SuperRetain_Private)
+ (id)defaultCollector;
@end

@implementation NSObject (SuperRetain)

Class gGarbageCollectorClass = nil;

+ (void)load
{

    gGarbageCollectorClass = NSClassFromString(@"NSGarbageCollector");

}

- (id)superRetain
{

    if ([gGarbageCollectorClass defaultCollector])
        CFRetain(self);
    
    else
        [self retain];
    
    return self;

}

- (void)superRelease
{

    if ([gGarbageCollectorClass defaultCollector])
        NSMakeCollectable(self);
    
    else
        [self release];

}

- (id)superAutorelease
{

    if ([gGarbageCollectorClass defaultCollector])
        NSMakeCollectable(self);
    
    else
        [self autorelease];
    
    return self;

}

@end