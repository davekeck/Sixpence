#import "CALayer+AssuredPresentationLayer.h"

@implementation CALayer (AssuredPresentationLayer)

- (CALayer *)assuredPresentationLayer
{

    CALayer *result = nil;
    
    result = [self presentationLayer];
    
    if (!result || ![result isKindOfClass: [CALayer class]])
        result = self;
    
    return result;

}

@end