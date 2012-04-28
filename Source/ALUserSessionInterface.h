#import <Foundation/Foundation.h>

/* Class Interfaces */

@interface ALUserSessionInterface : ALSingleton
{
}

/* Methods */

@property(nonatomic, readonly) NSString *activeUserChangedNotification;

/* Returns the user names for the users that are currently logged-in to a GUI session. */

- (NSSet *)userNamesForExistingUserSessions;
- (NSString *)userNameForActiveUserSession;

@end