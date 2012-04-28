#import "NSRunLoop+GuaranteedRunMode.h"

static void fauxRunLoopSourceCallback(void *info) {}

@implementation NSRunLoop (GuaranteedRunMode)

- (SInt32)guaranteedRunMode: (NSString *)mode timeout: (NSTimeInterval)timeout returnAfterSourceHandled: (BOOL)returnAfterSourceHandled
{

    CFRunLoopSourceContext fauxRunLoopSourceContext;
    CFRunLoopSourceRef fauxRunLoopSource = nil;
    SInt32 result = 0;
    
        NSParameterAssert(mode && [mode length]);
    
    /* We'll create a sham run loop source so that the run loop doesn't exit until the timeout, or until an actual run loop source is handled. */
    
    memset(&fauxRunLoopSourceContext, 0, sizeof(fauxRunLoopSourceContext));
    fauxRunLoopSourceContext.version = 0;
    fauxRunLoopSourceContext.perform = fauxRunLoopSourceCallback;
    
    fauxRunLoopSource = (CFRunLoopSourceRef)[(id)CFRunLoopSourceCreate(nil, 0, &fauxRunLoopSourceContext) superAutorelease];
    
    CFRunLoopAddSource([self getCFRunLoop], fauxRunLoopSource, (CFStringRef)mode);
    CFRunLoopWakeUp([self getCFRunLoop]);
    
    result = CFRunLoopRunInMode((CFStringRef)mode, timeout, returnAfterSourceHandled);
    
    CFRunLoopSourceInvalidate(fauxRunLoopSource);
    CFRunLoopWakeUp([self getCFRunLoop]);
    
    return result;

}

@end