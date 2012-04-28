// Garbage Collection
//   o implemented simple error-checking -finalize
//   o verified uses of &

#import "ALDistributedPreferences.h"

#import "NSData+Hash.h"

#import "ALDistributedLock.h"

#pragma mark Private Constants
#pragma mark -

static NSString *const ALDistributedPreferences_LockPathFormat = @"/tmp/ALDistributedPreferences.%@.lock"; /* The lock path consists of the hash of the file path. */

#pragma mark Property Redeclarations
#pragma mark -

@interface ALDistributedPreferences ()

/* Public Properties */

@property(nonatomic, readwrite, retain) NSString *filePath;
@property(nonatomic, readwrite, retain) NSMutableDictionary *defaults;
@property(nonatomic, readwrite, retain) NSMutableDictionary *valueTransformers;

/* Private Properties */

@property(nonatomic, nonatomic, retain) NSDictionary *cachedEntries;
@property(nonatomic, retain) ALDistributedLock *lock;
@property(nonatomic, retain) NSMutableDictionary *transactionEntries;

@end

#pragma mark -
#pragma mark Private Method Interfaces
#pragma mark -

@interface ALDistributedPreferences (Private)

#pragma mark -

/* Private Methods */

- (BOOL)finishTransactionAndRelinquishLockIfNeeded: (BOOL)relinquishLock;
- (void)prepareToModifyTransactionEntriesAndCreateIfNecessary: (BOOL)createTransactionEntriesIfNecessary;

@end

#pragma mark -

@implementation ALDistributedPreferences

#pragma mark -
#pragma mark Creation
#pragma mark -

- (id)initWithFilePath: (NSString *)newFilePath
{

        /* Verify our arguments. */
        
        NSParameterAssert(newFilePath && [newFilePath length]);
    
    if (!(self = [super init]))
        goto failed;
    
    [self setFilePath: newFilePath];
    
    /* Create our lock within the scope of the current user. */
    
    [self setLock: [[[ALDistributedLock alloc] initWithPath: [NSString stringWithFormat: ALDistributedPreferences_LockPathFormat,
        [filePath stringHashWithType: al_hash_hash_type_sha256]]] autorelease]];
    
        ALAssertOrPerform(lock, goto failed);
    
    [self setDefaults: [NSMutableDictionary dictionary]];
    [self setValueTransformers: [NSMutableDictionary dictionary]];
    
    /* By default, we don't want to update our cachedEntries automatically after a time interval has passed; that is, by default, we only update our
       cached entries once (the first time a value is requested) and simply use this same cachedEntries from there on out. See -entries for more info. */
    
    updateEntriesTimeInterval = -1.0;
    
    return self;
    
    failed:
    {
    
        [self release];
    
    }
    
    return nil;

}

- (void)dealloc
{

        /* Verify that we're not in the middle of a transaction. If we're being deallocated while we are, something's fucked. */
        
        NSParameterAssert(!transactionCounter);
    
    /* First we'll reset the objects that we created after we were initialized. */
    
    [self setCachedEntries: nil];
    [self setTransactionEntries: nil];
    [self setDelegate: nil];
    
    /* ... and now we'll reset the objects created in -initWithFilePath: */
    
    [self setValueTransformers: nil];
    [self setDefaults: nil];
    [self setLock: nil];
    [self setFilePath: nil];
    
    [super dealloc];

}

- (void)finalize
{

        /* Verify that we're not in the middle of a transaction. If we're being deallocated while we are, something's fucked. */
        
        NSParameterAssert(!transactionCounter);
    
    [super finalize];

}

#pragma mark -
#pragma mark Public Properties

@synthesize filePath;
@synthesize defaults;
@synthesize valueTransformers;
@synthesize writeDefaults;
@synthesize updateEntriesTimeInterval;
@synthesize delegate;

#pragma mark -
#pragma mark Private Properties
#pragma mark -

@synthesize cachedEntries;
@synthesize lock;
@synthesize transactionEntries;

- (void)setCachedEntries: (NSDictionary *)newCachedEntries
{

    [newCachedEntries retain];
    [cachedEntries release];
    cachedEntries = newCachedEntries;
    
    lastCachedEntriesUpdateTime = al_time_current_time();

}

#pragma mark -
#pragma mark Subclass Override Methods
#pragma mark -

- (NSData *)readData
{

    return [NSData dataWithContentsOfFile: filePath];

}

- (BOOL)writeData: (NSData *)data
{

    BOOL writeToFileResult = NO;
    
        NSParameterAssert(data);
    
    writeToFileResult = [data writeToFile: filePath atomically: YES];
    
        ALAssertOrPerform(writeToFileResult, return NO);
    
    return YES;

}

#pragma mark -
#pragma mark Methods
#pragma mark -

+ (NSDictionary *)dictionaryFromData: (NSData *)data
{

    NSDictionary *propertyListFromDataResult = nil;
    
        NSParameterAssert(data);
    
    propertyListFromDataResult = [NSPropertyListSerialization propertyListWithData: data options: NSPropertyListImmutable format: nil error: nil];
    
        ALAssertOrPerform([propertyListFromDataResult isKindOfClass: [NSDictionary class]], return nil);
    
    return propertyListFromDataResult;

}

+ (NSData *)dataFromDictionary: (NSDictionary *)dictionary
{

    NSData *dataFromPropertyListResult = nil;
    
        NSParameterAssert(dictionary);
    
    dataFromPropertyListResult = [NSPropertyListSerialization dataWithPropertyList: dictionary
        format: NSPropertyListBinaryFormat_v1_0 options: 0 error: nil];
    
        ALAssertOrPerform(dataFromPropertyListResult, return nil);
    
    return dataFromPropertyListResult;

}

- (BOOL)boolForKey: (NSString *)key
{

    id object = nil;
    
    object = [self objectForKey: key];
    
        ALAssertOrRaise(object && [object isKindOfClass: [NSNumber class]]);
    
    return [object boolValue];

}

- (BOOL)setBOOL: (BOOL)newBOOL forKey: (NSString *)key
{

    return [self setObject: [NSNumber numberWithBool: newBOOL] forKey: key];

}

- (NSInteger)integerForKey: (NSString *)key
{

    id object = nil;
    
    object = [self objectForKey: key];
    
        ALAssertOrRaise(object && [object isKindOfClass: [NSNumber class]]);
    
    return [object integerValue];

}

- (BOOL)setInteger: (NSInteger)newInteger forKey: (NSString *)key
{

    return [self setObject: [NSNumber numberWithInteger: newInteger] forKey: key];

}

- (double)doubleForKey: (NSString *)key
{

    id object = nil;
    
    object = [self objectForKey: key];
    
        ALAssertOrRaise(object && [object isKindOfClass: [NSNumber class]]);
    
    return [object doubleValue];

}

- (BOOL)setDouble: (double)newDouble forKey: (NSString *)key
{

    return [self setObject: [NSNumber numberWithDouble: newDouble] forKey: key];

}

- (id)valueForKey: (NSString *)key
{

    return [self objectForKey: key];

}

- (void)setValue: (id)newValue forKey: (NSString *)key
{

    [self setObject: newValue forKey: key];

}

- (id)objectForKey: (NSString *)key
{

    id result = nil;
    
        NSParameterAssert(key);
    
    result = [[self entries] objectForKey: key];
    
    /* If the normal entries dictionary doesn't have a value for the given key,
       request it from the defaults dictionary. */
    
    if (!result)
        result = [defaults objectForKey: key];
    
    return result;

}

- (BOOL)setObject: (id)newObject forKey: (NSString *)key
{

    BOOL transactionResult = NO;
    
        NSParameterAssert(newObject);
        NSParameterAssert(key);
    
    transactionResult = [self startTransaction];
    
        ALAssertOrPerform(transactionResult, return NO);
    
    [self prepareToModifyTransactionEntriesAndCreateIfNecessary: YES];
    [transactionEntries setObject: newObject forKey: key];
    
    transactionResult = [self finishTransaction];
    
        ALAssertOrPerform(transactionResult, return NO);
    
    return YES;

}

- (BOOL)removeObjectForKey: (NSString *)key
{

    BOOL transactionResult = NO;
    
        NSParameterAssert(key);
    
    transactionResult = [self startTransaction];
    
        ALAssertOrPerform(transactionResult, return NO);
    
    [self prepareToModifyTransactionEntriesAndCreateIfNecessary: YES];
    [transactionEntries removeObjectForKey: key];
    
    transactionResult = [self finishTransaction];
    
        ALAssertOrPerform(transactionResult, return NO);
    
    return YES;

}

- (NSDictionary *)entries
{

    NSDictionary *result = nil;
    
    /* Check whether A) a transaction is in progress and B) whether this transaction has modified our entries.
       If both are true, then transactionEntries holds our values, not cachedEntries. */
    
    if (transactionCounter && transactionEntries)
        result = transactionEntries;
    
    else
    {
    
        /* We need to update the cached entries in the following scenerios:
             
             o we don't yet have a cachedEntries;
             o updateEntriesTimeInterval >= 0.0, and this time interval has passed since the last time we updated the cached entries. */
        
        if (!cachedEntries || al_time_timeout_has_elapsed(lastCachedEntriesUpdateTime, updateEntriesTimeInterval))
        {
        
            BOOL updateEntriesFromDiskResult = NO;
            
            updateEntriesFromDiskResult = [self updateEntriesFromDisk];
            
                ALAssertOrPerform(updateEntriesFromDiskResult, return nil);
        
        }
        
        result = cachedEntries;
    
    }
    
    return result;

}

- (BOOL)setEntries: (NSDictionary *)newEntries
{

    BOOL transactionResult = NO;
    
        NSParameterAssert(newEntries);
    
    transactionResult = [self startTransaction];
    
        ALAssertOrPerform(transactionResult, return NO);
    
    [self prepareToModifyTransactionEntriesAndCreateIfNecessary: NO];
    [self setTransactionEntries: [[newEntries mutableCopy] autorelease]];
    
    transactionResult = [self finishTransaction];
    
        ALAssertOrPerform(transactionResult, return NO);
    
    return YES;

}

- (BOOL)startTransaction
{

    BOOL acquiredLock = NO,
         result = NO;
    
        ALAssertOrRaise(transactionCounter < NSUIntegerMax);
    
    if (!transactionCounter)
    {
    
        if (delegate && [delegate respondsToSelector: @selector(distributedUserDefaultsWillStartTransaction:)])
            [delegate distributedUserDefaultsWillStartTransaction: self];
    
    }
    
    transactionCounter++;
    
    if (transactionCounter == 1)
    {
    
        NSDictionary *primitiveEntries = nil;
        NSMutableDictionary *complexEntries = nil;
        NSString *currentKey = nil;
        NSData *readData = nil;
        BOOL lockWithTimeoutResult = NO;
        
        /* First we need to acquire the lock before we read the preferences file. */
        
        lockWithTimeoutResult = [lock lockWithTimeout: -1.0];
        
            ALAssertOrPerform(lockWithTimeoutResult, goto cleanup);
        
        acquiredLock = YES;
        
        readData = [self readData];
        
        if (readData)
            primitiveEntries = [[self class] dictionaryFromData: readData];
        
        /* Note that we're not considering !primitiveEntries an error. This is because NSPropertyListSerialization returns an error
           when the data length is 0, and possibly other cases. Either way, +propertyListFromData will return nil, and we'll
           just have an empty primitiveEntries, and silently eat the error.
           
           If we weren't able to create a dictionary from the plist data, then we'll simply create an empty dictionary, so we at
           least have something to hand to -migrateEntries: */
        
        if (!primitiveEntries)
            primitiveEntries = [NSDictionary dictionary];
        
        /* Give subclasses a chance to migrate our raw entries to whatever format that need to be in.
           
           Note that we're presenting the entries to -migrateEntries: _without_ any of our transformers applied (from
           the valueTransformers dictionary.) We want it this way because in general, one can't make assumptions
           about the type of a certain key's value, without first considering the authoring version of the software
           that wrote the value; therefore, we're supplying the entries in their raw form. */
        
        primitiveEntries = [self migrateEntries: primitiveEntries];
        
        /* Unarchive/transform our values from their representation on disk, to their in-memory representation.
           
           Note that we can't modify a dictionary being enumerated while it's being enumerated, therefore we're
           creating a new dictionary (transformedEntries) that we'll modify during the enumeration. */
        
        complexEntries = [NSMutableDictionary dictionary];
        
        for (currentKey in primitiveEntries)
        {
        
            id currentObject = nil;
            NSValueTransformer *valueTransformer = nil;
            
            currentObject = [primitiveEntries objectForKey: currentKey];
            valueTransformer = [valueTransformers objectForKey: currentKey];
            
            if (valueTransformer)
                currentObject = [valueTransformer transformedValue: currentObject];
            
            [complexEntries setObject: currentObject forKey: currentKey];
        
        }
        
        /* Update our cachedEntries with the entries we read from disk, and reset our transactionEntries. */
        
        [self setCachedEntries: complexEntries];
        [self setTransactionEntries: nil];
    
    }
    
    result = YES;
    
    cleanup:
    {
    
        /* There's no need to check the result below since we already know we failed. */
        
        if (!result)
            [self finishTransactionAndRelinquishLockIfNeeded: acquiredLock];
    
    }
    
    return result;

}

- (BOOL)finishTransaction
{

    return [self finishTransactionAndRelinquishLockIfNeeded: YES];

}

- (BOOL)updateEntriesFromDisk
{

    /* Creating a transaction is how we update our cached entries. */
    
    BOOL transactionResult = NO;
    
    transactionResult = [self startTransaction];
    
        ALAssertOrPerform(transactionResult, return NO);
    
    transactionResult = [self finishTransaction];
    
        ALAssertOrPerform(transactionResult, return NO);
    
    return YES;

}

- (NSDictionary *)migrateEntries: (NSDictionary *)newEntries
{

    /* Stock method does nothing; subclasses should override this method to migrate the given entries to a format
       that the current running version of the software will understand. */
    
    return newEntries;

}

#pragma mark -
#pragma mark Private Methods
#pragma mark -

- (BOOL)finishTransactionAndRelinquishLockIfNeeded: (BOOL)relinquishLock
{

    BOOL result = NO;
    
        /* Verify that our transaction counter isn't already 0 */
        
        ALAssertOrRaise(transactionCounter);
    
    if (transactionCounter == 1 && transactionEntries)
    {
    
        NSMutableDictionary *complexEntries = nil,
                            *primitiveEntries = nil;
        NSString *currentKey = nil;
        NSData *data = nil;
        BOOL writeDataResult = NO;
        
        complexEntries = [NSMutableDictionary dictionary];
        primitiveEntries = [NSMutableDictionary dictionary];
        
        /* If we've been instructed to do so, write our defaults to disk (with non-default values taking precedence). */
        
        if (writeDefaults)
            [complexEntries addEntriesFromDictionary: defaults];
        
        [complexEntries addEntriesFromDictionary: transactionEntries];
        
        /* Transform our entries to be plist-compatible, so they can be written to disk. */
        
        for (currentKey in complexEntries)
        {
        
            id currentObject = nil;
            NSValueTransformer *valueTransformer = nil;
            
            currentObject = [complexEntries objectForKey: currentKey];
            valueTransformer = [valueTransformers objectForKey: currentKey];
            
            if (valueTransformer && [[valueTransformer class] allowsReverseTransformation])
                currentObject = [valueTransformer reverseTransformedValue: currentObject];
            
            [primitiveEntries setObject: currentObject forKey: currentKey];
        
        }
        
        data = [[self class] dataFromDictionary: primitiveEntries];
        
            ALAssertOrPerform(data, goto cleanup);
        
        writeDataResult = [self writeData: data];
        
            ALConfirmOrPerform(writeDataResult, goto cleanup);
        
        [self setCachedEntries: complexEntries];
    
    }
    
    result = YES;
    
    cleanup:
    {
    
        if (transactionCounter == 1 && relinquishLock)
        {
        
            BOOL unlockResult = NO;
            
            /* Unlock the lock, regardless of whether we saved successfully. */
            
            unlockResult = [lock unlock];
            
                ALAssertOrPerform(unlockResult, result = NO);
        
        }
        
        transactionCounter--;
        
        if (!transactionCounter)
        {
        
            if (delegate && [delegate respondsToSelector: @selector(distributedUserDefaultsDidFinishTransaction:)])
                [delegate distributedUserDefaultsDidFinishTransaction: self];
        
        }
    
    }
    
    return result;

}

- (void)prepareToModifyTransactionEntriesAndCreateIfNecessary: (BOOL)createTransactionEntriesIfNecessary
{

        /* We must be inside a transaction - it doesn't make sense to modify temp entries outside of one, because
           the changes would never get committed. */
        
        ALAssertOrRaise(transactionCounter);
    
    if (!transactionEntries && createTransactionEntriesIfNecessary)
    {
    
        /* Set up our temporary entries. The values changed by our -set... methods are actually changing the
           transactionEntries dictionary, which is simply an up-to-date cachedEntries, and therefore transactionEntries
           is ultimately a copy of the on-disk preferences. transactionEntries is not committed until the final,
           outer -finishTransaction is called. */
        
        [self setTransactionEntries: [[cachedEntries mutableCopy] autorelease]];
    
    }

}

@end