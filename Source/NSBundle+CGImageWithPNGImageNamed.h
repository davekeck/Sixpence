#import <Cocoa/Cocoa.h>

@interface NSBundle (CGImageWithPNGImageNamed)

/* The result of this method is autoreleased. */

- (CGImageRef)CGImageWithPNGImageNamed: (NSString *)imageName;

@end