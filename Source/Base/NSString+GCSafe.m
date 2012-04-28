//#warning we can drop this class once GC supports interior pointers

#import "NSString+GCSafe.h"

#import "ALStickyGarbage.h"

@implementation NSString (GCSafe)

- (const char *__strong)GCSafeUTF8String
{

    const char *__strong result = nil;
    
    result = [self UTF8String];
    
    if (result)
        [[ALStickyGarbage currentStickyGarbage] markStickyGarbage: result];
    
    return result;

}

- (const char *__strong)GCSafeCStringUsingEncoding: (NSStringEncoding)encoding
{

    const char *__strong result = nil;
    
    result = [self cStringUsingEncoding: encoding];
    
    if (result)
        [[ALStickyGarbage currentStickyGarbage] markStickyGarbage: result];
    
    return result;

}

- (const char *__strong)GCSafeFileSystemRepresentation
{

    const char *__strong result = nil;
    
    result = [self fileSystemRepresentation];
    
    if (result)
        [[ALStickyGarbage currentStickyGarbage] markStickyGarbage: result];
    
    return result;

}

@end