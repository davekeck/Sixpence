#import "NSShadow+Creation.h"

#pragma mark Category Implementations
#pragma mark -

@implementation NSShadow (Creation)

#pragma mark -
#pragma mark Creation
#pragma mark -

- (NSShadow *)initWithColor: (NSColor *)color offset: (NSSize)offset blurRadius: (CGFloat)blurRadius
{

    if (!(self = [super init]))
        return nil;
    
    [self setShadowColor: color];
    [self setShadowOffset: offset];
    [self setShadowBlurRadius: blurRadius];
    
    return self;

}

+ (NSShadow *)shadowWithColor: (NSColor *)color offset: (NSSize)offset blurRadius: (CGFloat)blurRadius
{

    return [[[NSShadow alloc] initWithColor: color offset: offset blurRadius: blurRadius] autorelease];

}

@end