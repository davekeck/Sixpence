#import "ALDistributedPreferencesController.h"

#pragma mark Private Class Interfaces
#pragma mark -

@interface ALDistributedPreferencesController_Entries : NSObject
{

@private
    
    id controller;

}

/* Properties */

@property(nonatomic, assign) id controller;

@end

#pragma mark -
#pragma mark Property Redeclarations
#pragma mark -

@interface ALDistributedPreferencesController () <ALDistributedPreferences_Delegate>

@property(nonatomic, readwrite, retain) ALDistributedPreferences *distributedUserDefaults;
@property(nonatomic, readwrite, retain) id entries;

@end

#pragma mark -
#pragma mark Private Method Interfaces
#pragma mark -

@interface ALDistributedPreferencesController (Private)

#pragma mark -

- (void)prepareToChangeEntriesForKeys: (NSSet *)keys;
- (void)finishChangingEntries;

- (id)entriesValueForKey: (NSString *)key;
- (void)entriesSetValue: (id)value forKey: (NSString *)key;
- (void)entriesSetNilValueForKey: (NSString *)key;
- (void)entriesAddObserver: (id)observer forKeyPath: (NSString *)keyPath;
- (void)entriesRemoveObserver: (id)observer forKeyPath: (NSString *)keyPath;

@end

#pragma mark -
#pragma mark Class Implementations
#pragma mark -

@implementation ALDistributedPreferencesController

#pragma mark -
#pragma mark Creation
#pragma mark -

- (id)initWithDistributedUserDefaults: (ALDistributedPreferences *)newDistributedUserDefaults
{

        NSParameterAssert(newDistributedUserDefaults);
    
    if (!(self = [super init]))
        return nil;
    
    [self setDistributedUserDefaults: newDistributedUserDefaults];
    [distributedUserDefaults setDelegate: self];
    
    addedEntries = [[NSMutableDictionary alloc] init];
    removedEntriesKeys = [[NSMutableSet alloc] init];
    
    observedKeys = [[NSMutableSet alloc] init];
    changingKeys = [[NSPointerArray pointerArrayWithStrongObjects] retain];
    
    [self setEntries: [[ALDistributedPreferencesController_Entries alloc] init]];
    [((ALDistributedPreferencesController_Entries *)entries) setController: self];
    
    return self;

}

- (void)dealloc
{

    [self setEntries: nil];
    
    [changingKeys release],
    changingKeys = nil;
    
    [observedKeys release],
    observedKeys = nil;
    
    [removedEntriesKeys release],
    removedEntriesKeys = nil;
    
    [addedEntries release],
    addedEntries = nil;
    
    [self setDistributedUserDefaults: nil];
    
    [super dealloc];

}

#pragma mark -
#pragma mark Properties

@synthesize distributedUserDefaults;
@synthesize entries;

#pragma mark -
#pragma mark Delegate Methods
#pragma mark -

- (void)distributedUserDefaultsWillStartTransaction: (ALDistributedPreferences *)sender
{

    [self prepareToChangeEntriesForKeys: observedKeys];

}

- (void)distributedUserDefaultsDidFinishTransaction: (ALDistributedPreferences *)sender
{

    [self finishChangingEntries];

}

#pragma mark -
#pragma mark Subclass Override Methods
#pragma mark -

- (BOOL)willSave
{

    return YES;

}

- (void)didSaveWithResult: (BOOL)saveResult
{
}

#pragma mark -
#pragma mark Methods
#pragma mark -

- (BOOL)save
{

    NSMutableDictionary *newEntries = nil;
    NSString *currentRemovedEntryKey = nil;
    BOOL willSaveResult = NO,
         startTransactionResult = NO,
         startedTransaction = NO,
         setEntriesResult = NO,
         result = NO;
    
    /* We used to rely on our transaction-beginning delegate method (-distributedUserDefaultsWillStartTransaction:) to call our -willChange/-didChange
       KVO methods (via -prepareToChangeEntriesForKeys: and -finishChangingEntries). But as it turns out, we want to do this manually, so that if
       saving fails, our -didSaveWithResult: subclass-override method has the opportunity to discard pending changes, before the -didChange KVO
       meessages are sent. (Therefore, if saving fails, the KVO observers will never see any change in the preferences.) */
    
    [self prepareToChangeEntriesForKeys: observedKeys];
    
    willSaveResult = [self willSave];
    
        ALAssertOrPerform(willSaveResult, goto cleanup);
    
    startTransactionResult = [distributedUserDefaults startTransaction];
    
        ALAssertOrPerform(startTransactionResult, goto cleanup);
    
    startedTransaction = YES;
    
    newEntries = [[[distributedUserDefaults entries] mutableCopy] autorelease];
    
    for (currentRemovedEntryKey in removedEntriesKeys)
        [newEntries removeObjectForKey: currentRemovedEntryKey];
    
    [newEntries addEntriesFromDictionary: addedEntries];
    
    setEntriesResult = [distributedUserDefaults setEntries: newEntries];
    
        ALAssertOrPerform(setEntriesResult, goto cleanup);
    
    result = YES;
    
    cleanup:
    {
    
        if (startedTransaction)
        {
        
            BOOL finishTransactionResult = NO;
            
            finishTransactionResult = [distributedUserDefaults finishTransaction];
            
                ALConfirmOrPerform(finishTransactionResult, result = NO);
        
        }
        
        /* Only if we were successful in saving our changes will we remove our outstanding changes. */
        
        if (result)
        {
        
            [addedEntries removeAllObjects];
            [removedEntriesKeys removeAllObjects];
        
        }
        
        /* Notify subclasses that we're finished saving. */
        
        [self didSaveWithResult: result];
        
        /* And send our -didChange KVO messages. */
        
        [self finishChangingEntries];
    
    }
    
    return result;

}

- (void)discardPendingChanges
{

    NSMutableSet *pendingChangesKeys = nil;
    
    pendingChangesKeys = [NSMutableSet setWithArray: [addedEntries allKeys]];
    [pendingChangesKeys unionSet: removedEntriesKeys];
    
    [self prepareToChangeEntriesForKeys: pendingChangesKeys];
    [addedEntries removeAllObjects];
    [removedEntriesKeys removeAllObjects];
    [self finishChangingEntries];

}

- (void)discardPendingChangeForKey: (NSString *)key
{

        NSParameterAssert(key && [key length]);
    
    [self prepareToChangeEntriesForKeys: [NSSet setWithObject: key]];
    [addedEntries removeObjectForKey: key];
    [removedEntriesKeys removeObject: key];
    [self finishChangingEntries];

}

- (void)disableKVONotifications
{

        ALAssertOrRaise(![changingKeys count]);
        ALAssertOrRaise(disableKVONotificationsCounter < NSUIntegerMax);
    
    disableKVONotificationsCounter++;

}

- (void)enableKVONotifications
{

        ALAssertOrRaise(disableKVONotificationsCounter);
    
    disableKVONotificationsCounter--;

}

- (void)synchronizeUserInterface
{

    [self prepareToChangeEntriesForKeys: observedKeys];
    [self finishChangingEntries];

}

#pragma mark -
#pragma mark Private Methods
#pragma mark -

- (void)prepareToChangeEntriesForKeys: (NSSet *)keys
{

    NSSet *changingKeysSet = nil;
    NSMutableSet *newChangingKeys = nil;
    NSArray *newChangingKeysArray = nil;
    NSString *currentNewChangingKey = nil;
    
        NSParameterAssert(keys);
        ALConfirmOrPerform(!disableKVONotificationsCounter, return);
    
    changingKeysSet = [NSSet setWithArray: [changingKeys allObjects]];
    
    newChangingKeys = [[observedKeys mutableCopy] autorelease];
    [newChangingKeys intersectSet: keys];
    [newChangingKeys minusSet: changingKeysSet];
    newChangingKeysArray = [newChangingKeys allObjects];
    
    [changingKeys addPointer: nil];
    for (currentNewChangingKey in newChangingKeysArray)
    {
    
        [changingKeys addPointer: currentNewChangingKey];
        [entries willChangeValueForKey: currentNewChangingKey];
    
    }

}

- (void)finishChangingEntries
{

    NSUInteger i = 0;
    
        ALConfirmOrPerform(!disableKVONotificationsCounter, return);
    
    for (i = [changingKeys count]; i > 0; i--)
    {
    
        NSString *currentChangingKey = nil;
        
        currentChangingKey = [changingKeys pointerAtIndex: (i - 1)];
        
        if (currentChangingKey)
            [entries didChangeValueForKey: currentChangingKey];
        
        [changingKeys removePointerAtIndex: (i - 1)];
        
        if (!currentChangingKey)
            break;
    
    }

}

- (id)entriesValueForKey: (NSString *)key
{

    id result = nil;
    
        NSParameterAssert(key && [key length]);
    
    if ([removedEntriesKeys containsObject: key])
        result = [distributedUserDefaults.defaults objectForKey: key];
    
    else
    {
    
        result = [addedEntries objectForKey: key];
        
        if (!result)
            result = [distributedUserDefaults objectForKey: key];
    
    }
    
    return result;

}

- (void)entriesSetValue: (id)value forKey: (NSString *)key
{

        NSParameterAssert(value);
        NSParameterAssert(key && [key length]);
    
    [self prepareToChangeEntriesForKeys: [NSSet setWithObject: key]];
    [addedEntries setObject: value forKey: key];
    [removedEntriesKeys removeObject: key];
    [self save];
    [self finishChangingEntries];

}

- (void)entriesSetNilValueForKey: (NSString *)key
{

        NSParameterAssert(key && [key length]);
    
    [self prepareToChangeEntriesForKeys: [NSSet setWithObject: key]];
    [addedEntries removeObjectForKey: key];
    [removedEntriesKeys addObject: key];
    [self save];
    [self finishChangingEntries];

}

- (void)entriesAddObserver: (id)observer forKeyPath: (NSString *)keyPath
{

        NSParameterAssert(observer);
        NSParameterAssert(keyPath && [keyPath length]);
        NSParameterAssert([[[keyPath componentsSeparatedByString: @"."] objectAtIndex: 0] length]);
    
    [observedKeys addObject: [[keyPath componentsSeparatedByString: @"."] objectAtIndex: 0]];

}

- (void)entriesRemoveObserver: (id)observer forKeyPath: (NSString *)keyPath
{

        NSParameterAssert(observer);
        NSParameterAssert(keyPath && [keyPath length]);
        NSParameterAssert([[[keyPath componentsSeparatedByString: @"."] objectAtIndex: 0] length]);
        NSParameterAssert([observedKeys containsObject: [[keyPath componentsSeparatedByString: @"."] objectAtIndex: 0]]);
    
    [observedKeys removeObject: [[keyPath componentsSeparatedByString: @"."] objectAtIndex: 0]];

}

@end

#pragma mark -
#pragma mark Private Class Implementations
#pragma mark -

@implementation ALDistributedPreferencesController_Entries

#pragma mark -
#pragma mark Properties

@synthesize controller;

#pragma mark -
#pragma mark Override Methods
#pragma mark -

- (id)valueForKey: (NSString *)key
{

    return [controller entriesValueForKey: key];

}

- (void)setValue: (id)newValue forKey: (NSString *)key
{

    [controller entriesSetValue: newValue forKey: key];

}

- (void)setNilValueForKey: (NSString *)key
{

    [controller entriesSetNilValueForKey: key];

}

- (void)addObserver: (NSObject *)observer forKeyPath: (NSString *)keyPath options: (NSKeyValueObservingOptions)options context: (void *)context
{

    [controller entriesAddObserver: observer forKeyPath: keyPath];
    [super addObserver: observer forKeyPath: keyPath options: options context: context];

}

- (void)removeObserver: (NSObject *)observer forKeyPath: (NSString *)keyPath
{

    [super removeObserver: observer forKeyPath: keyPath];
    [controller entriesRemoveObserver: observer forKeyPath: keyPath];

}

@end