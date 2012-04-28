// Garbage Collection
//   o finalize not necessary

#import "ALSecureTextFieldCell.h"

#import "ALSynthesizeCellCommonInit.h"

#pragma mark Property Redeclarations
#pragma mark -

@interface ALSecureTextFieldCell ()

@property(nonatomic, retain) NSMutableString *mutablePassword;

@end

#pragma mark -
#pragma mark Class Implementations
#pragma mark -

@implementation ALSecureTextFieldCell

#pragma mark -
#pragma mark Creation
#pragma mark -

ALSynthesizeCellCommonInit(ALSecureTextFieldCell);

- (id)commonInit
{

    [self setMutablePassword: [NSMutableString string]];
    
    return self;

}

- (void)dealloc
{

    [self setMutablePassword: nil];
    
    [super dealloc];

}

#pragma mark -
#pragma mark Public Properties

@dynamic password;

- (NSString *)password
{

    return mutablePassword;

}

#pragma mark -
#pragma mark Private Properties
#pragma mark -

@synthesize mutablePassword;

#pragma mark -
#pragma mark Methods
#pragma mark -

- (void)clearPassword
{

    /* Clear our backing store and our visual representation. */
    
    [self setMutablePassword: [NSMutableString string]];
    [self setStringValue: @""];

}

#pragma mark -
#pragma mark Accessibility Methods
#pragma mark -

- (NSArray *)accessibilityAttributeNames
{

    return [[super accessibilityAttributeNames] arrayByAddingObjectsFromArray:
        [NSArray arrayWithObjects: NSAccessibilityRoleAttribute, NSAccessibilityRoleDescriptionAttribute, nil]];

}

- (id)accessibilityAttributeValue: (NSString *)attribute
{

        NSParameterAssert(attribute && [attribute length]);
    
    if ([attribute isEqualToString: NSAccessibilityRoleAttribute])
        return NSAccessibilityUnknownRole;
    
    else if ([attribute isEqualToString: NSAccessibilityRoleDescriptionAttribute])
        return NSAccessibilityRoleDescription(NSAccessibilityTextFieldRole, NSAccessibilitySecureTextFieldSubrole);
    
    return [super accessibilityAttributeValue: attribute];

}

@end

#pragma mark -

@implementation ALSecureTextView

#pragma mark -
#pragma mark Creation
#pragma mark -

- (id)init
{

    if (!(self = [super initWithFrame: NSZeroRect]))
        return nil;
    
    [self setEditable: YES];
    [self setSelectable: YES];
    [self setFieldEditor: YES];
    
    return self;

}

#pragma mark -
#pragma mark Override Methods
#pragma mark -

- (BOOL)shouldChangeTextInRange: (NSRange)range replacementString: (NSString *)string
{

    NSTextField *textField = nil;
    ALSecureTextFieldCell *cell = nil;
    NSMutableString *mutablePassword = nil;
    
        /* Verify our arguments. Note that [string length] == 0 is permitted. */
        
        NSParameterAssert(string);
    
    textField = (NSTextField *)[self delegate];
    
        ALAssertOrPerform(textField && [textField isKindOfClass: [NSTextField class]], return NO);
    
    cell = [textField cell];
    
        ALAssertOrPerform(cell && [cell isKindOfClass: [ALSecureTextFieldCell class]], return NO);
    
    mutablePassword = cell.mutablePassword;
    
        ALAssertOrPerform(mutablePassword, return NO);
    
    [mutablePassword replaceCharactersInRange: range withString: string];
    
    return [super shouldChangeTextInRange: range replacementString: string];

}

- (void)didChangeText
{

    NSTextStorage *textStorage = nil;
    NSMutableString *replacementString = nil;
    NSUInteger textStorageLength = 0,
               i = 0;
    NSRange previousSelection;
    
    textStorage = [self textStorage];
    
    replacementString = [NSMutableString string];
    
    textStorageLength = [textStorage length];
    
    previousSelection = [self selectedRange];
    
    for (i = 0; i < textStorageLength; i++)
        [replacementString appendString: @"\u2022"];
    
    [textStorage replaceCharactersInRange: NSMakeRange(0, textStorageLength) withString: replacementString];
    
    [self setSelectedRange: previousSelection];
    
    [super didChangeText];

}

- (NSArray *)writablePasteboardTypes
{

    /* Prevent copy */
    
    return [NSArray array];

}

- (BOOL)writeSelectionToPasteboard: (NSPasteboard *)pboard type: (NSString *)type
{

    /* Prevent copy */
    
    return NO;

}

- (BOOL)writeSelectionToPasteboard: (NSPasteboard *)pboard types: (NSArray *)types
{

    /* Prevent copy */
    
    return NO;

}

- (BOOL)dragSelectionWithEvent: (NSEvent *)event offset: (NSSize)mouseOffset slideBack: (BOOL)slideBack
{

    /* Prevent dragging within the text view */
    
    return NO;

}

@end