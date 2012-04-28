#import <Foundation/Foundation.h>

@interface NSString (GCSafe)

- (const char *__strong)GCSafeUTF8String;
- (const char *__strong)GCSafeCStringUsingEncoding: (NSStringEncoding)encoding;
- (const char *__strong)GCSafeFileSystemRepresentation;

@end