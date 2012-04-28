#import <Cocoa/Cocoa.h>

#import "ALCompositor.h"

@interface ALStyledTextCompositor : ALCompositor
{

@private
    
    NSGradient *textGradient;
    NSShadow *textShadow;

}

/* Methods */

+ (id)startWithRect: (NSRect)rect textGradient: (NSGradient *)textGradient textShadow: (NSShadow *)textShadow;

/* Properties */

@property(nonatomic, retain) NSGradient *textGradient;
@property(nonatomic, retain) NSShadow *textShadow;

@end