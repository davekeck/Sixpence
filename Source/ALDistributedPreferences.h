#import <Foundation/Foundation.h>

/* Forward Declarations */

@class ALDistributedLock;
@class ALDistributedPreferences;

/* Protocols */

@protocol ALDistributedPreferences_Delegate
@optional

- (void)distributedUserDefaultsWillStartTransaction: (ALDistributedPreferences *)sender;
- (void)distributedUserDefaultsDidFinishTransaction: (ALDistributedPreferences *)sender;

@end

@interface ALDistributedPreferences : NSObject
{

@private
    
    NSString *filePath;
    
    NSDictionary *cachedEntries;
    NSMutableDictionary *transactionEntries;
    double lastCachedEntriesUpdateTime;
    
    NSMutableDictionary *defaults;
    NSMutableDictionary *valueTransformers;
    
    ALDistributedLock *lock;
    NSUInteger transactionCounter;
    
    BOOL writeDefaults;
    NSTimeInterval updateEntriesTimeInterval;
    __weak id <NSObject, ALDistributedPreferences_Delegate> delegate;

}

/* Creation */

/* The designated initializer */

- (id)initWithFilePath: (NSString *)newFilePath;

/* Properties */

@property(nonatomic, readonly, retain) NSString *filePath;
@property(nonatomic, readonly, retain) NSMutableDictionary *defaults;
@property(nonatomic, readonly, retain) NSMutableDictionary *valueTransformers;

/* This value determines whether the defaults (from the 'defaults' property) are written to disk. It has no immediate effect; the
   defaults are only written when a transaction is finished. */

@property(nonatomic, assign) BOOL writeDefaults;

/* When requesting values for keys, this is the time interval that must have passed before the values are updated from 
   A negative updateEntriesTimeInterval means the values will not be updated from disk, except for their initial load from disk. A
   value of 0.0 means the values will be updated from disk everytime one is requested.
   
   By default, the entires will only be read from disk once, upon the initial request for a value.
   
   ### Note, though, that this property does not apply when changing (writing) values. Anytime a value is changed, the ALDUD is
       updated from disk, the value is changed, and the changes are written back to disk. This transactional process prevents
       clobbering values written by other processes. */

@property(nonatomic, assign) NSTimeInterval updateEntriesTimeInterval;
@property(nonatomic, assign) __weak id <NSObject, ALDistributedPreferences_Delegate> delegate;

/* Subclass Override Methods */

/* These two methods are meant to be overridden by subclasses, allowing them to override the standard reading/writing functionality.
   This allows subclasses to read/write data from/to an arbitrary file, not necessarily the same file given to -initWithFilePath:.
   
   In the case of -readData, the return value can be nil, a zero-length data object, or the data of a property list.
   
   -writeData should return YES if the operation succeeds and the transaction should continue. data is guaranteed != nil
   (but [data length] may == 0.) */

- (NSData *)readData;
- (BOOL)writeData: (NSData *)data;

/* Methods */

+ (NSDictionary *)dictionaryFromData: (NSData *)data;
+ (NSData *)dataFromDictionary: (NSDictionary *)dictionary;

/* These convenience methods raise an exception if no object exists for the given key, or if it's type is not an NSNumber. */

- (BOOL)boolForKey: (NSString *)key;
- (BOOL)setBOOL: (BOOL)newBool forKey: (NSString *)key;

- (NSInteger)integerForKey: (NSString *)key;
- (BOOL)setInteger: (NSInteger)newInteger forKey: (NSString *)key;

- (double)doubleForKey: (NSString *)key;
- (BOOL)setDouble: (double)newDouble forKey: (NSString *)key;

- (id)valueForKey: (NSString *)key; /* Same as -objectForKey: */
- (void)setValue: (id)value forKey: (NSString *)key; /* Same as setObject: forKey: */

- (id)objectForKey: (NSString *)key;
- (BOOL)setObject: (id)object forKey: (NSString *)key;
- (BOOL)removeObjectForKey: (NSString *)key;

- (NSDictionary *)entries;
- (BOOL)setEntries: (NSDictionary *)newEntries;

/* These two methods allows you to group operations into one transaction, so the file will only
   be written once. Note that if -startTransaction returns NO, then you should _not_ call
   -finishTransaction; everything's already been cleaned up for you. */

- (BOOL)startTransaction;
- (BOOL)finishTransaction;

/* This method will update the receiver's values from disk. Note that this method is implicitly
   called any time a value is changed (using one of the -set... methods) or when a transaction
   is started. */

- (BOOL)updateEntriesFromDisk;

/* This method is meant to be overriden by subclasses. It provides a mechanism to migrate the entries
   loaded from disk to a new format, if necessary. (It's intended use is updating preferences files
   written by older versions of the software, to be read by the current version.) This method should
   make whatever changes necessary to the given newEntries, and return the result. nil is a valid
   return value.
   
   newEntries is guaranteed non-nil (but of course, the dictionary could be empty.)
   
   ### The entries stored in the supplied newEntries argument do _not_ have any value transformations
       applied (ie, from the valueTransformers property), nor does it contain any defaults that weren't
       saved to disk (the defaults property.) In other words, the 'newEntries' argument contains the
       pure, unaltered objects formed from the property list data returned from -readData. */

- (NSDictionary *)migrateEntries: (NSDictionary *)newEntries;

@end