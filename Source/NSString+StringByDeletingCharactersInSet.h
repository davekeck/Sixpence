#import <Foundation/Foundation.h>

@interface NSString (StringByDeletingCharactersInSet)

- (NSString *)stringByDeletingCharactersInSet: (NSCharacterSet *)characterSet;

@end