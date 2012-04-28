#import "ALInaccessibleControls.h"

#define ALSynthesizeInaccessibleControlMethods()                                                              \
                                                                                                              \
    - (NSArray *)accessibilityAttributeNames { return nil; }                                                  \
    - (id)accessibilityAttributeValue: (NSString *)attribute { return nil; }                                  \
    - (BOOL)accessibilityIsAttributeSettable: (NSString *)attribute { return NO; }                            \
    - (void)accessibilitySetValue: (id)value forAttribute: (NSString *)attribute {}                           \
                                                                                                              \
    - (NSArray *)accessibilityParameterizedAttributeNames { return nil; }                                     \
    - (id)accessibilityAttributeValue: (NSString *)attribute forParameter: (id)parameter { return nil; }      \
                                                                                                              \
    - (NSArray *)accessibilityActionNames { return nil; }                                                     \
    - (NSString *)accessibilityActionDescription: (NSString *)action { return nil; }                          \
    - (void)accessibilityPerformAction: (NSString *)action {}                                                 \
    - (BOOL)accessibilityIsIgnored { return NO; }                                                             \
    - (id)accessibilityHitTest: (NSPoint)point { return nil; }                                                \
    - (id)accessibilityFocusedUIElement { return nil; }

@implementation ALInaccessibleTextField

ALSynthesizeInaccessibleControlMethods();

@end

@implementation ALInaccessibleButton

ALSynthesizeInaccessibleControlMethods();

@end

@implementation ALInaccessibleImageView

ALSynthesizeInaccessibleControlMethods();

@end