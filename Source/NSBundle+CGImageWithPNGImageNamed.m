#import "NSBundle+CGImageWithPNGImageNamed.h"

@implementation NSBundle (CGImageWithPNGImageNamed)

- (CGImageRef)CGImageWithPNGImageNamed: (NSString *)imageName
{

    CGDataProviderRef imageDataProvider = nil;
    CGImageRef result = nil;
    
        NSParameterAssert(imageName && [imageName length]);
    
    imageDataProvider = (CGDataProviderRef)[(id)CGDataProviderCreateWithURL((CFURLRef)[NSURL fileURLWithPath: [self pathForResource: imageName ofType: @"png"]]) superAutorelease];
    
        ALAssertOrPerform(imageDataProvider, return nil);
    
    result = (CGImageRef)[(id)CGImageCreateWithPNGDataProvider(imageDataProvider, nil, NO, kCGRenderingIntentDefault) superAutorelease];
    
        ALAssertOrPerform(result, return nil);
    
    return result;

}

@end