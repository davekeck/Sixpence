#import <Foundation/Foundation.h>

#import "ALDistributedPreferences.h"

@interface ALDistributedPreferencesController : NSObject
{

@private
    
    ALDistributedPreferences *distributedUserDefaults;
    id entries;
    
    NSMutableDictionary *addedEntries;
    NSMutableSet *removedEntriesKeys;
    
    NSMutableSet *observedKeys;
    NSPointerArray *changingKeys;
    
    NSUInteger disableKVONotificationsCounter;

}

/* Creation */

- (id)initWithDistributedUserDefaults: (ALDistributedPreferences *)newDistributedUserDefaults;

/* Properties */

@property(nonatomic, readonly, retain) ALDistributedPreferences *distributedUserDefaults;
@property(nonatomic, readonly, retain) id entries;

/* Subclass Override Methods */

- (BOOL)willSave;
- (void)didSaveWithResult: (BOOL)saveResult;

/* Methods */

- (BOOL)save;

- (void)discardPendingChanges;
- (void)discardPendingChangeForKey: (NSString *)key;

- (void)disableKVONotifications;
- (void)enableKVONotifications;

- (void)synchronizeUserInterface;

@end