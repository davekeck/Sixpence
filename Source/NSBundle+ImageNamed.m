#import "NSBundle+ImageNamed.h"

@implementation NSBundle (ImageNamed)

- (NSImage *)imageNamed: (NSString *)imageName
{

    NSURL *imageURL = nil;
    
        NSParameterAssert(imageName && [imageName length]);
    
    imageURL = [self URLForImageResource: imageName];
    
        ALAssertOrPerform(imageURL, return nil);
    
    return [[[NSImage alloc] initWithContentsOfURL: imageURL] autorelease];

}

@end