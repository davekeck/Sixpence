#import "NSControl+ForceUpdate.h"

@implementation NSControl (ForceUpdate)

- (void)forceUpdate
{

    id originalObjectValue = nil;
    
    originalObjectValue = [self objectValue];
    
        ALAssertOrPerform(originalObjectValue && [originalObjectValue isKindOfClass: [NSNumber class]], return);
    
    [self setObjectValue: [NSNumber numberWithBool: ![originalObjectValue boolValue]]];
    [self setObjectValue: originalObjectValue];

}

@end