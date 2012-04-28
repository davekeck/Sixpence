#import <Cocoa/Cocoa.h>

@interface ALSecureTextFieldCell : NSTextFieldCell
{

@private
    
    NSMutableString *mutablePassword;

}

/* Properties */

@property(nonatomic, readonly) NSString *password;

/* Methods */

/* This is the only way that you should modify the contents of an ALSecureTextFieldCell programatically. */

- (void)clearPassword;

@end

/* The window containing a ALSecureTextFieldCell should have a delegate that implements -windowWillReturnFieldEditor:..., as such:

    - (id)windowWillReturnFieldEditor: (NSWindow *)window toObject: (id)object
    {
    
        if ([object isKindOfClass: [NSTextField class]] && [[object cell] isKindOfClass: [ALSecureTextFieldCell class]])
        {
        
            static ALSecureTextView *secureFieldEditor = nil;
            
            if (!secureFieldEditor)
                secureFieldEditor = [[ALSecureTextView alloc] init];
            
            return secureFieldEditor;
        
        }
        
        return nil;
    
    }

*/

@interface ALSecureTextView : NSTextView
{
}

@end