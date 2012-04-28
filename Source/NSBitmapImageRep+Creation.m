#import "NSBitmapImageRep+Creation.h"

#import "NSBitmapImageRep+LockFocus.h"

@implementation NSBitmapImageRep (Creation)

#pragma mark -
#pragma mark Creation
#pragma mark -

+ (NSBitmapImageRep *)bitmapImageRepWithPixelsWide: (NSInteger)pixelsWide pixelsHigh: (NSInteger)pixelsHigh
{

    return [[[NSBitmapImageRep alloc] initWithPixelsWide: pixelsWide pixelsHigh: pixelsHigh colorSpaceName: nil] autorelease];

}

+ (NSBitmapImageRep *)bitmapImageRepWithPixelsWide: (NSInteger)pixelsWide pixelsHigh: (NSInteger)pixelsHigh colorSpaceName: (NSString *)colorSpaceName
{

    return [[[NSBitmapImageRep alloc] initWithPixelsWide: pixelsWide pixelsHigh: pixelsHigh colorSpaceName: colorSpaceName] autorelease];

}

+ (NSBitmapImageRep *)bitmapImageRepWithImage: (NSImage *)image
{

    NSBitmapImageRep *result = nil;
    
        NSParameterAssert(image);
    
    result = [image bitmapImageRep];
    
    if (!result)
    {
    
        NSInteger pixelsWide = 0,
                  pixelsHigh = 0;
        
        pixelsWide = lround([image size].width);
        pixelsHigh = lround([image size].height);
        
        result = [NSBitmapImageRep bitmapImageRepWithPixelsWide: pixelsWide pixelsHigh: pixelsHigh];
        
            ALAssertOrPerform(result, return nil);
        
        [result lockFocus];
        
        NSRectFillUsingOperation(NSMakeRect(0.0, 0.0, pixelsWide, pixelsHigh), NSCompositeClear);
        
        [image drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
        
        [result unlockFocus];
    
    }
    
    return result;

}

- (id)initWithPixelsWide: (NSInteger)pixelsWide pixelsHigh: (NSInteger)pixelsHigh
{

    return [self initWithPixelsWide: pixelsWide pixelsHigh: pixelsHigh colorSpaceName: nil];

}

- (id)initWithPixelsWide: (NSInteger)pixelsWide pixelsHigh: (NSInteger)pixelsHigh colorSpaceName: (NSString *)colorSpaceName
{

    NSInteger samplesPerPixel = 0;
    
        NSParameterAssert(pixelsWide > 0);
        NSParameterAssert(pixelsHigh > 0);
        NSParameterAssert(!colorSpaceName ||
                          [colorSpaceName isEqualToString: NSCalibratedRGBColorSpace] ||
                          [colorSpaceName isEqualToString: NSDeviceRGBColorSpace] ||
                          [colorSpaceName isEqualToString: NSDeviceCMYKColorSpace]);
    
    /* If a color space name isn't specified, we assume NSCalibratedRGBColorSpace. */
    
    if (!colorSpaceName)
        colorSpaceName = NSCalibratedRGBColorSpace;
    
    /* Determine the number of samples per pixel. */
    
    if ([colorSpaceName isEqualToString: NSCalibratedRGBColorSpace] || [colorSpaceName isEqualToString: NSDeviceRGBColorSpace])
        samplesPerPixel = 4;
    
    else if ([colorSpaceName isEqualToString: NSDeviceCMYKColorSpace])
        samplesPerPixel = 5;
    
    if (!(self = [self initWithBitmapDataPlanes: nil pixelsWide: pixelsWide pixelsHigh: pixelsHigh bitsPerSample: 8 samplesPerPixel: samplesPerPixel hasAlpha: YES
                        isPlanar: NO colorSpaceName: colorSpaceName bytesPerRow: (pixelsWide * samplesPerPixel) bitsPerPixel: (samplesPerPixel * 8)]))
        return nil;
    
    return self;

}

@end

#pragma mark Category Implementations
#pragma mark -

@implementation NSImage (NSBitmapImageRepCreation)

#pragma mark -
#pragma mark Methods
#pragma mark -

- (NSBitmapImageRep *)bitmapImageRep
{

    NSImageRep *currentImageRep = nil;
    
    for (currentImageRep in [self representations])
    {
    
        if ([currentImageRep isKindOfClass: [NSBitmapImageRep class]])
            return (NSBitmapImageRep *)currentImageRep;
    
    }
    
    return nil;

}

@end