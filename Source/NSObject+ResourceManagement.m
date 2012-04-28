#import "NSObject+ResourceManagement.h"

#import <objc/runtime.h>

@interface NSObject (ResourceManagement_Private)
- (NSMutableDictionary *)resourceRetainCounts;
@end

@implementation NSObject (ResourceManagement)

- (NSMutableDictionary *)resourceRetainCounts
{

    static dispatch_once_t onceToken = 0;
    static NSString *kKey = nil;
    NSMutableDictionary *result = nil;
    
    dispatch_once(&onceToken,
    ^{
    
        kKey = ALUniqueStringForThisMethod;
    
    });
    
    @synchronized(self)
    {
    
        result = objc_getAssociatedObject(self, kKey);
        
        if (!result)
        {
        
            result = [[NSMapTable alloc] initWithKeyOptions: (NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality)
                valueOptions: (NSPointerFunctionsOpaqueMemory | NSPointerFunctionsIntegerPersonality) capacity: 0];
            
            objc_setAssociatedObject(self, kKey, result, OBJC_ASSOCIATION_RETAIN);
        
        }
    
    }
    
    return result;

}

- (void)retainResource: (void *)resource
{

    NSMutableDictionary *resourceRetainCounts = nil;
    
        NSParameterAssert(resource);
    
    resourceRetainCounts = [self resourceRetainCounts];
    
    @synchronized(resourceRetainCounts)
    {
    
        uintptr_t retainCount = 0;
        
        if (![resourceRetainCounts count])
            [self superRetain];
        
        retainCount = (uintptr_t)[resourceRetainCounts objectForKey: (id)resource];
        
            ALAssertOrRaise(retainCount < ALIntMaxValueForObject(retainCount));
        
        retainCount++;
        [resourceRetainCounts setObject: (id)retainCount forKey: (id)resource];
    
    }


}

- (void)releaseResource: (void *)resource
{

    NSMutableDictionary *resourceRetainCounts = nil;
    
        NSParameterAssert(resource);
    
    resourceRetainCounts = [self resourceRetainCounts];
    
    @synchronized(resourceRetainCounts)
    {
    
        uintptr_t retainCount = 0;
        
        retainCount = (uintptr_t)[resourceRetainCounts objectForKey: (id)resource];
        
            ALAssertOrRaise(retainCount);
        
        retainCount--;
        
        if (retainCount)
            [resourceRetainCounts setObject: (id)retainCount forKey: (id)resource];
        
        else
        {
        
            [resourceRetainCounts removeObjectForKey: (id)resource];
            
            /* Callout after the line above, so the callout can call -retainResource/-releaseResource safely. */
            
            [self cleanupResource: resource];
        
        }
        
        /* Autorelease instead of release so we're not released while we still hold the lock on resourceRetainCounts. */
        
        if (![resourceRetainCounts count])
            [self superAutorelease];
    
    }

}

- (void)cleanupResource: (void *)resource
{

    [NSException raise: NSGenericException format: @""];

}

@end