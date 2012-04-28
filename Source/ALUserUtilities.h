#import <Foundation/Foundation.h>

/* Class Interfaces */

@interface ALUserUtilities : ALSingleton

/* Result: user ID */

- (al_uid_t)userIDForUserName: (NSString *)userName;

/* Result: user name */

- (NSString *)userNameForUserID: (uid_t)userID;

/* Result: group ID */

- (al_gid_t)groupIDForUserID: (uid_t)userID;
- (al_gid_t)groupIDForUserName: (NSString *)userName;
- (al_gid_t)groupIDForGroupName: (NSString *)groupName;

/* Result: group name */

- (NSString *)groupNameForUserID: (uid_t)userID;
- (NSString *)groupNameForUserName: (NSString *)userName;
- (NSString *)groupNameForGroupID: (gid_t)groupID;

- (BOOL)userIDExists: (uid_t)userID;
- (BOOL)userNameExists: (NSString *)userName;

- (BOOL)groupIDExists: (gid_t)groupID;
- (BOOL)groupNameExists: (NSString *)groupName;

@end