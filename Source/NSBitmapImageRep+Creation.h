#import <Cocoa/Cocoa.h>

@interface NSBitmapImageRep (Creation)

+ (NSBitmapImageRep *)bitmapImageRepWithPixelsWide: (NSInteger)pixelsWide pixelsHigh: (NSInteger)pixelsHigh;
+ (NSBitmapImageRep *)bitmapImageRepWithPixelsWide: (NSInteger)pixelsWide pixelsHigh: (NSInteger)pixelsHigh colorSpaceName: (NSString *)colorSpaceName;
+ (NSBitmapImageRep *)bitmapImageRepWithImage: (NSImage *)image;

- (id)initWithPixelsWide: (NSInteger)pixelsWide pixelsHigh: (NSInteger)pixelsHigh;
- (id)initWithPixelsWide: (NSInteger)pixelsWide pixelsHigh: (NSInteger)pixelsHigh colorSpaceName: (NSString *)colorSpaceName;

@end

@interface NSImage (NSBitmapImageRep_Creation)

- (NSBitmapImageRep *)bitmapImageRep;

@end