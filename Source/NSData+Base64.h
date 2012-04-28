#import <Foundation/Foundation.h>

@interface NSData (Base64)

- (NSString *)encodeWithBase64;

@end

@interface NSString (Base64)

- (NSData *)decodeWithBase64;

@end