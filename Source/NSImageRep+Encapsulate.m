#import "NSImageRep+Encapsulate.h"

@implementation NSImageRep (Encapsulate)

- (NSImage *)encapsulate
{

    NSImage *result = nil;
    
    result = [[[NSImage alloc] initWithSize: NSMakeSize([self pixelsWide], [self pixelsHigh])] autorelease];
    
        ALAssertOrPerform(result, return nil);
    
    [result addRepresentation: self];
    
    return result;

}

@end