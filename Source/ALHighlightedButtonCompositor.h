#import <Cocoa/Cocoa.h>

#import "ALCompositor.h"

@interface ALHighlightedButtonCompositor : ALCompositor
{

@private
    
    NSColor *highlightColor;

}

/* Methods */

+ (id)startWithRect: (NSRect)rect highlightColor: (NSColor *)highlightColor;

/* Properties */

@property(nonatomic, retain) NSColor *highlightColor;

@end