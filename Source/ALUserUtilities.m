// Garbage Collection
//   o verified uses of &

#import "ALUserUtilities.h"

#import <pwd.h>
#import <grp.h>

#pragma mark Class Implementations
#pragma mark -

@implementation ALUserUtilities

#pragma mark -
#pragma mark Methods
#pragma mark -

/* Result: user ID */

- (al_uid_t)userIDForUserName: (NSString *)userName
{

    struct passwd *userInfo = nil;
    
        NSParameterAssert(userName);
    
    userInfo = getpwnam([userName GCSafeUTF8String]);
    
        ALAssertOrPerform(userInfo, return al_uid_init);
    
    return al_uid_create(YES, userInfo->pw_uid);

}

/* Result: user name */

- (NSString *)userNameForUserID: (uid_t)userID
{

    struct passwd *userInfo = nil;
    
    userInfo = getpwuid(userID);
    
        ALAssertOrPerform(userInfo, return nil);
        ALAssertOrPerform(userInfo->pw_name, return nil);
    
    return [NSString stringWithUTF8String: userInfo->pw_name];

}

/* Result: group ID */

- (al_gid_t)groupIDForUserID: (uid_t)userID
{

    struct passwd *userInfo = nil;
    
    userInfo = getpwuid(userID);
    
        ALAssertOrPerform(userInfo, return al_gid_init);
    
    return al_gid_create(YES, userInfo->pw_gid);

}

- (al_gid_t)groupIDForUserName: (NSString *)userName
{

    struct passwd *userInfo = nil;
    
        NSParameterAssert(userName);
    
    userInfo = getpwnam([userName GCSafeUTF8String]);
    
        ALAssertOrPerform(userInfo, return al_gid_init);
    
    return al_gid_create(YES, userInfo->pw_gid);

}

- (al_gid_t)groupIDForGroupName: (NSString *)groupName
{

    struct group *groupInfo = nil;
    
        NSParameterAssert(groupName);
    
    groupInfo = getgrnam([groupName GCSafeUTF8String]);
    
        ALAssertOrPerform(groupInfo, return al_gid_init);
    
    return al_gid_create(YES, groupInfo->gr_gid);

}

/* Result: group name */

- (NSString *)groupNameForUserID: (uid_t)userID
{

    struct passwd *userInfo = nil;
    struct group *groupInfo = nil;
    
    userInfo = getpwuid(userID);
    
        ALAssertOrPerform(userInfo, return nil);
    
    groupInfo = getgrgid(userInfo->pw_gid);
    
        ALAssertOrPerform(groupInfo, return nil);
        ALAssertOrPerform(groupInfo->gr_name, return nil);
    
    return [NSString stringWithUTF8String: groupInfo->gr_name];

}

- (NSString *)groupNameForUserName: (NSString *)userName
{

    struct passwd *userInfo = nil;
    struct group *groupInfo = nil;
    
        NSParameterAssert(userName);
    
    userInfo = getpwnam([userName GCSafeUTF8String]);
    
        ALAssertOrPerform(userInfo, return nil);
    
    groupInfo = getgrgid(userInfo->pw_gid);
    
        ALAssertOrPerform(groupInfo, return nil);
        ALAssertOrPerform(groupInfo->gr_name, return nil);
    
    return [NSString stringWithUTF8String: groupInfo->gr_name];

}

- (NSString *)groupNameForGroupID: (gid_t)groupID
{

    struct group *groupInfo = nil;
    
    groupInfo = getgrgid(groupID);
    
        ALAssertOrPerform(groupInfo, return nil);
        ALAssertOrPerform(groupInfo->gr_name, return nil);
    
    return [NSString stringWithUTF8String: groupInfo->gr_name];

}

- (BOOL)userIDExists: (uid_t)userID
{

    return (getpwuid(userID) != nil);

}

- (BOOL)userNameExists: (NSString *)userName
{

        NSParameterAssert(userName);
    
    return (getpwnam([userName GCSafeUTF8String]) != nil);

}

- (BOOL)groupIDExists: (gid_t)groupID
{

    return (getgrgid(groupID) != nil);

}

- (BOOL)groupNameExists: (NSString *)groupName
{

        NSParameterAssert(groupName);
    
    return (getgrnam([groupName GCSafeUTF8String]) != nil);

}

@end