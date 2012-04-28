#import <Cocoa/Cocoa.h>

@interface ALLinkTextButton : NSButton
{

@private
    
    NSURL *url;
    BOOL initialized;

}

/* Properties */

@property(nonatomic, retain, setter=setURL:) NSURL *url;

@end