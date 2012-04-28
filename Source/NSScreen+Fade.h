#import <Cocoa/Cocoa.h>

@interface NSScreen (Fade)

+ (BOOL)startFadeWithDuration: (NSTimeInterval)duration waitUntilFinished: (BOOL)waitUntilFinished;
+ (BOOL)finishFadeWithDuration: (NSTimeInterval)duration waitUntilFinished: (BOOL)waitUntilFinished;

@end