#import <Cocoa/Cocoa.h>

@interface ALCompositor : NSObject
{

@private
    
    NSRect rect;
    NSBitmapImageRep *bitmapImageRep;

}

/* Methods */

+ (id)startWithRect: (NSRect)newRect;
- (void)finish;

/* Properties */

@property(nonatomic, assign) NSRect rect;
@property(nonatomic, retain) NSBitmapImageRep *bitmapImageRep;

/* Subclass Override Methods */

- (void)willLockFocusOnBitmapImageRep;
- (void)didLockFocusOnBitmapImageRep;

- (void)willUnlockFocusOnBitmapImageRep;
- (void)didUnlockFocusOnBitmapImageRep;

- (void)willDrawBitmapImageRep;
- (void)didDrawBitmapImageRep;

@end