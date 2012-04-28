#import "NSProcessInfo+HostSerialNumber.h"

#import <IOKit/IOKitLib.h>

#pragma mark Static Variables
#pragma mark -

static NSString *NSProcessInfo_HostSerialNumber_HostSerialNumber = nil;

#pragma mark Category Implementations
#pragma mark -

@implementation NSProcessInfo (HostSerialNumber)

#pragma mark -

- (NSString *)hostSerialNumber
{

    io_service_t service = MACH_PORT_NULL;
    
    if (!NSProcessInfo_HostSerialNumber_HostSerialNumber)
    {
    
        CFDictionaryRef matchingDictionary = nil;
        
        /* Form a matching dictionary for our 'platform expert' service */
        
        matchingDictionary = (CFDictionaryRef)[(id)IOServiceMatching("IOPlatformExpertDevice") superAutorelease];
        
            ALAssertOrPerform(matchingDictionary, goto cleanup);
        
        /* Retrieve the 'platform expert' service. We need to CFRetain matchingDictionary because IOServiceGetMatchingService() consumes a reference,
           and we autorelease matchingDictionary above. */
        
        service = IOServiceGetMatchingService(kIOMasterPortDefault, CFRetain(matchingDictionary));
        
            ALAssertOrPerform(service != MACH_PORT_NULL, goto cleanup);
        
        /* Finally, get the serial number and keep it around in our static variable, so we only have to retrieve it once. */
        
        NSProcessInfo_HostSerialNumber_HostSerialNumber = (NSString *)IORegistryEntryCreateCFProperty(service, (CFStringRef)@kIOPlatformSerialNumberKey, nil, 0);
        
            ALAssertOrPerform(NSProcessInfo_HostSerialNumber_HostSerialNumber, goto cleanup);
    
    }
    
    cleanup:
    {
    
        if (service != MACH_PORT_NULL)
            IOObjectRelease(service),
            service = MACH_PORT_NULL;
    
    }
    
    return NSProcessInfo_HostSerialNumber_HostSerialNumber;

}

@end