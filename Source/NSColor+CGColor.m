#import "NSColor+CGColor.h"

@implementation NSColor (CGColor)

+ (NSColor *)colorWithCGColor: (CGColorRef)cgColor
{

    NSColorSpace *colorSpace = nil;
    const CGFloat *colorComponents = nil;
    NSInteger numberOfColorComponents = 0;
    NSColor *result = nil;
    
        NSParameterAssert(cgColor);
    
    colorSpace = [[[NSColorSpace alloc] initWithCGColorSpace: CGColorGetColorSpace(cgColor)] autorelease];
    
        ALAssertOrPerform(colorSpace, return nil);
    
    colorComponents = CGColorGetComponents(cgColor);
    
        ALAssertOrPerform(colorComponents, return nil);
    
    numberOfColorComponents = CGColorGetNumberOfComponents(cgColor);
    
        ALAssertOrPerform(numberOfColorComponents, return nil);
    
    result = [NSColor colorWithColorSpace: colorSpace components: colorComponents count: numberOfColorComponents];
    
        ALAssertOrPerform(result, return nil);
    
    return result;

}

- (CGColorRef)CGColor
{

    CGColorSpaceRef colorSpace = nil;
    CGFloat *colorComponents = nil;
    CGColorRef result = nil;
    
    colorSpace = [[self colorSpace] CGColorSpace];
    
        ALAssertOrPerform(colorSpace, goto cleanup);
    
    /* Allocate the space for the color components that we'll pass to CGColorCreate(). */
    
    colorComponents = malloc(sizeof(*colorComponents) * [self numberOfComponents]);
    
        ALAssertOrPerform(colorComponents, goto cleanup);
    
    [self getComponents: colorComponents];
    
    result = (CGColorRef)[(id)CGColorCreate(colorSpace, (const CGFloat *)colorComponents) superAutorelease];
    
    cleanup:
    {
    
        if (colorComponents)
            free(colorComponents),
            colorComponents = nil;
    
    }
    
    return result;

}

@end