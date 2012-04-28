// Garbage Collection
//   o verified uses of &

#import "ALSystemVersion.h"

#pragma mark Definitions
#pragma mark -

#define ALSystemVersion_ReturnSystemVersionType(systemVersionType)                          \
                                                                                            \
    static NSInteger result = -1;                                                           \
                                                                                            \
    @synchronized(self)                                                                     \
    {                                                                                       \
                                                                                            \
        if (result < 0)                                                                     \
        {                                                                                   \
                                                                                            \
            SInt32 temp = 0;                                                                \
            OSErr gestaltResult = 0;                                                        \
                                                                                            \
            gestaltResult = Gestalt(systemVersionType, &temp);                              \
                                                                                            \
                ALAssertOrPerform(gestaltResult == noErr && temp >= 0, return 0);           \
                                                                                            \
            result = temp;                                                                  \
                                                                                            \
        }                                                                                   \
                                                                                            \
    }                                                                                       \
                                                                                            \
    return result

#define ALSystemVersion_ReturnSystemVersionString(systemVersionStringFormat)                                     \
                                                                                                                 \
    NSInteger majorVersion = 0,                                                                                  \
              minorVersion = 0,                                                                                  \
              bugFixVersion = 0;                                                                                 \
                                                                                                                 \
    majorVersion = [self majorVersion];                                                                          \
                                                                                                                 \
        ALAssertOrPerform(majorVersion >= 0, return nil);                                                        \
                                                                                                                 \
    minorVersion = [self minorVersion];                                                                          \
                                                                                                                 \
        ALAssertOrPerform(minorVersion >= 0, return nil);                                                        \
                                                                                                                 \
    bugFixVersion = [self bugFixVersion];                                                                        \
                                                                                                                 \
        ALAssertOrPerform(bugFixVersion >= 0, return nil);                                                       \
                                                                                                                 \
    return [NSString stringWithFormat: systemVersionStringFormat, majorVersion, minorVersion, bugFixVersion]

#pragma mark -
#pragma mark Type Definitions
#pragma mark -

enum
{

    ALSystemVersion_ComparisonType_Equal,
    ALSystemVersion_ComparisonType_AtLeast,
    ALSystemVersion_ComparisonType_AtMost,
    
    _ALSystemVersion_ComparisonType_Length,
    _ALSystemVersion_ComparisonType_First = ALSystemVersion_ComparisonType_Equal, 

}; typedef int ALSystemVersion_ComparisonType;

#pragma mark -
#pragma mark Constants
#pragma mark -

NSString *const ALSystemVersion_TigerVersion = @"10.4";
NSString *const ALSystemVersion_LeopardVersion = @"10.5";
NSString *const ALSystemVersion_SnowLeopardVersion = @"10.6";
NSString *const ALSystemVersion_LionVersion = @"10.7";

#pragma mark Private Method Interfaces
#pragma mark -

@interface ALSystemVersion (Private)

#pragma mark -

/* Private Methods */

+ (BOOL)compareVersion: (NSString *)versionString usingComparisonType: (ALSystemVersion_ComparisonType)comparisonType;

@end

#pragma mark -
#pragma mark Class Implementations
#pragma mark -

@implementation ALSystemVersion

#pragma mark -
#pragma mark Methods
#pragma mark -

+ (NSInteger)majorVersion
{

    ALSystemVersion_ReturnSystemVersionType(gestaltSystemVersionMajor);

}

+ (NSInteger)minorVersion
{

    ALSystemVersion_ReturnSystemVersionType(gestaltSystemVersionMinor);

}

+ (NSInteger)bugFixVersion
{

    ALSystemVersion_ReturnSystemVersionType(gestaltSystemVersionBugFix);

}

+ (NSString *)majorVersionString
{

    ALSystemVersion_ReturnSystemVersionString(@"%lu");

}

+ (NSString *)majorMinorVersionString
{

    ALSystemVersion_ReturnSystemVersionString(@"%lu.%lu");

}

+ (NSString *)majorMinorBugFixVersionString
{

    ALSystemVersion_ReturnSystemVersionString(@"%lu.%lu.%lu");

}

+ (BOOL)isVersion: (NSString *)versionString
{

    return [self compareVersion: versionString usingComparisonType: ALSystemVersion_ComparisonType_Equal];

}

+ (BOOL)isAtLeastVersion: (NSString *)versionString
{

    return [self compareVersion: versionString usingComparisonType: ALSystemVersion_ComparisonType_AtLeast];

}

+ (BOOL)isAtMostVersion: (NSString *)versionString
{

    return [self compareVersion: versionString usingComparisonType: ALSystemVersion_ComparisonType_AtMost];

}

#pragma mark -
#pragma mark Private Methods
#pragma mark -

+ (BOOL)compareVersion: (NSString *)versionString usingComparisonType: (ALSystemVersion_ComparisonType)comparisonType
{

    NSInteger versionComponents[3];
    NSArray *versionComponentStrings = nil;
    NSUInteger numberOfVersionComponentStrings = 0,
               i = 0;
    
        NSParameterAssert(versionString && [versionString length]);
        NSParameterAssert(ALValueInRangeExclusive(comparisonType, _ALSystemVersion_ComparisonType_First, _ALSystemVersion_ComparisonType_Length));
    
    versionComponents[0] = [self majorVersion];
    
        ALAssertOrPerform(versionComponents[0] >= 0, return NO);
    
    versionComponents[1] = [self minorVersion];
    
        ALAssertOrPerform(versionComponents[1] >= 0, return NO);
    
    versionComponents[2] = [self bugFixVersion];
    
        ALAssertOrPerform(versionComponents[2] >= 0, return NO);
    
    versionComponentStrings = [versionString componentsSeparatedByString: @"."];
    
        ALAssertOrPerform(versionComponentStrings, return NO);
    
    numberOfVersionComponentStrings = [versionComponentStrings count];
    
        ALAssertOrPerform(ALValueInRange(numberOfVersionComponentStrings, 1, 3), return NO);
    
    for (i = 0; i < numberOfVersionComponentStrings; i++)
    {
    
        NSInteger currentVersionComponent = 0;
        
        currentVersionComponent = [[versionComponentStrings objectAtIndex: i] integerValue];
        
            ALAssertOrPerform(currentVersionComponent >= 0, return NO);
        
        if (comparisonType == ALSystemVersion_ComparisonType_Equal)
        {
        
            if (currentVersionComponent != versionComponents[i])
                return NO;
        
        }
        
        else if (comparisonType == ALSystemVersion_ComparisonType_AtLeast)
        {
        
            if (currentVersionComponent < versionComponents[i])
                return YES;
            
            else if (currentVersionComponent > versionComponents[i])
                return NO;
        
        }
        
        else if (comparisonType == ALSystemVersion_ComparisonType_AtMost)
        {
        
            if (currentVersionComponent > versionComponents[i])
                return YES;
            
            else if (currentVersionComponent < versionComponents[i])
                return NO;
        
        }
    
    }
    
    return YES;

}

@end