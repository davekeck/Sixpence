#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>

/* Constants */

extern NSString *const ALSystemVersion_TigerVersion;
extern NSString *const ALSystemVersion_LeopardVersion;
extern NSString *const ALSystemVersion_SnowLeopardVersion;
extern NSString *const ALSystemVersion_LionVersion;

/* Class Interfaces */

@interface ALSystemVersion : NSObject
{
}

/* On error, these methods return < 0. */

+ (NSInteger)majorVersion;
+ (NSInteger)minorVersion;
+ (NSInteger)bugFixVersion;

/* On error, these methods return nil. */

+ (NSString *)majorVersionString;
+ (NSString *)majorMinorVersionString;
+ (NSString *)majorMinorBugFixVersionString;

/* With these methods, you can pass any format (ie, N, N.N, or N.N.N). */

+ (BOOL)isVersion: (NSString *)versionString;
+ (BOOL)isAtLeastVersion: (NSString *)versionString;
+ (BOOL)isAtMostVersion: (NSString *)versionString;

@end