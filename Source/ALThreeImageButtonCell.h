#import <Cocoa/Cocoa.h>

@interface ALThreeImageButtonCell : NSButtonCell
{

@private
    
    NSImage *leftCapImage;
    NSImage *centerFillImage;
    NSImage *rightCapImage;

}

/* Properties */

@property(nonatomic, retain) NSImage *leftCapImage;
@property(nonatomic, retain) NSImage *centerFillImage;
@property(nonatomic, retain) NSImage *rightCapImage;

@end