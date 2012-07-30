#import <Cocoa/Cocoa.h>

@interface NSBundle (ImageNamed)

- (NSImage *)imageNamed: (NSString *)imageName;

@end