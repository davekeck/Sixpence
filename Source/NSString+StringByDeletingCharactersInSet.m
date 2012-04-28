#import "NSString+StringByDeletingCharactersInSet.h"

@implementation NSString (StringByDeletingCharactersInSet)

- (NSString *)stringByDeletingCharactersInSet: (NSCharacterSet *)characterSet
{

    NSUInteger i = 0;
    NSMutableString *result = nil;
    
        NSParameterAssert(characterSet);
    
    result = [[self mutableCopy] autorelease];
    
    for (i = [result length]; i > 0; i--)
    {
    
        if ([characterSet characterIsMember: [result characterAtIndex: (i - 1)]])
            [result deleteCharactersInRange: NSMakeRange((i - 1), 1)];
    
    }
    
    return result;

}

@end