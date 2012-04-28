// Garbage Collection
//   o verified uses of &

#import "NSData+Base64.h"

#import "al_base64.h"

@implementation NSData (Base64)

- (NSString *)encodeWithBase64
{

    char *encodedDataString = nil;
    NSString *result = nil;
    
    /* Required because we're using NSData's -bytes. */
    
    [self superRetain];
    
    encodedDataString = al_base64_encode_data([self bytes], [self length]);
    
        /* Verify our output. Note that encodedDataString == NULL is considered an error, but strlen(encodedDataString) == 0 is not. */
        
        ALAssertOrPerform(encodedDataString, goto cleanup);
    
    result = [NSString stringWithUTF8String: encodedDataString];
    
    cleanup:
    {
    
        if (encodedDataString)
            free(encodedDataString),
            encodedDataString = nil;
        
        /* Balance superRetain above. */
        
        [self superRelease],
        self = nil;
    
    }
    
    return result;

}

@end

@implementation NSString (Base64)

- (NSData *)decodeWithBase64
{

    void *decodedData = nil;
    size_t decodedDataLength = 0;
    NSData *result = nil;
    
    decodedData = al_base64_decode_data([self GCSafeUTF8String], &decodedDataLength);
    
        /* Verify our output. Note that decodedData == NULL is considered an error, but decodedDataLength == 0 is not. */
        
        ALAssertOrPerform(decodedData, goto cleanup);
    
    result = [NSData dataWithBytesNoCopy: decodedData length: decodedDataLength];
    
    cleanup:
    {
    
        if (!result && decodedData)
            free(decodedData),
            decodedData = nil;
    
    }
    
    return result;

}

@end