#import <Cocoa/Cocoa.h>

@interface NSWorkspace (AuthenticateUser)

/* username must be a user's shortname. Neither arguments can be nil.
   username cannot be an empty string, and password can be an empty string. */

+ (BOOL)authenticateUser: (NSString *)username password: (NSString *)password;

@end