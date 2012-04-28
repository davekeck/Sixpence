#import <Cocoa/Cocoa.h>

@interface ALGradientShadowLabelCell : NSTextFieldCell
{

@private
    
    NSGradient *textGradient;
    NSShadow *textShadow;

}

/* Properties */

@property(nonatomic, retain) NSGradient *textGradient;
@property(nonatomic, retain) NSShadow *textShadow;

@end