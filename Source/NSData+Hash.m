#import "NSData+Hash.h"

#import <CommonCrypto/CommonDigest.h>

#pragma mark Category Implementations
#pragma mark -

@implementation NSData (Hash)

#pragma mark -
#pragma mark Methods
#pragma mark -

- (NSData *)hashWithType: (al_hash_hash_type)hashType
{

    void *hashData = nil;
    NSData *result = nil;
    
    /* Required because we're using NSData's -bytes. */
    
    [self superRetain];
    
    /* Hash our data. */
    
    hashData = al_hash_data_hash(hashType, [self bytes], [self length]);
    
        ALAssertOrPerform(hashData, goto cleanup);
    
    result = [NSData dataWithBytesNoCopy: hashData length: al_hash_data_hash_length_for_hash_type(hashType)];
    
    cleanup:
    {
    
        if (!result && hashData)
            free(hashData),
            hashData = nil;
        
        /* Balance superRetain above. */
        
        [self superRelease],
        self = nil;
    
    }
    
    return result;

}

- (NSString *)stringHashWithType: (al_hash_hash_type)hashType
{

    char *hashString = nil;
    NSString *result = nil;
    
    /* Required because we're using NSData's -bytes. */
    
    [self superRetain];
    
    /* Hash our data. */
    
    hashString = al_hash_string_hash(hashType, [self bytes], [self length]);
    
        ALAssertOrPerform(hashString, goto cleanup);
    
    result = [NSString stringWithUTF8String: hashString];
    
    cleanup:
    {
    
        if (hashString)
            free(hashString),
            hashString = nil;
        
        /* Balance superRetain above. */
        
        [self superRelease],
        self = nil;
    
    }
    
    return result;

}

@end

#pragma mark -

@implementation NSString (Hash)

#pragma mark -
#pragma mark Methods
#pragma mark -

- (NSData *)hashWithType: (al_hash_hash_type)hashType
{

    /* Note that -dataUsingEncoding does not return a NULL-terminated string, which in this case, is exactly the behavior we want. */
    
    return [[self dataUsingEncoding: NSUTF8StringEncoding] hashWithType: hashType];

}

- (NSString *)stringHashWithType: (al_hash_hash_type)hashType
{

    /* Note that -dataUsingEncoding does not return a NULL-terminated string, which in this case, is exactly the behavior we want. */
    
    return [[self dataUsingEncoding: NSUTF8StringEncoding] stringHashWithType: hashType];

}

@end