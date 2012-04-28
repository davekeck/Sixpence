#import "NSApplication+TickleEventQueue.h"

@implementation NSApplication (TickleEventQueue)

- (void)tickleEventQueue
{

    [NSApp postEvent: [NSEvent otherEventWithType: NSApplicationDefined location: NSZeroPoint modifierFlags: 0 timestamp: 0.0
        windowNumber: 0 context: nil subtype: 0 data1: 0 data2: 0] atStart: NO];

}

@end