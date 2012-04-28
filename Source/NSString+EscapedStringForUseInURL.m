#import "NSString+EscapedStringForUseInURL.h"

@implementation NSString (EscapedStringForUseInURL)

- (NSString *)escapedStringForUseInURL
{

    return [(id)CFURLCreateStringByAddingPercentEscapes(nil, (CFStringRef)self, nil, (CFStringRef)@";/?:@&=+$,[]#!'()* ", kCFStringEncodingUTF8) superAutorelease];

}

@end