// Garbage Collection
//   o verified uses of &

#import "NSWorkspace+AuthenticateUser.h"

#import <Security/Security.h>

@implementation NSWorkspace (AuthenticateUser)

+ (BOOL)authenticateUser: (NSString *)username password: (NSString *)password
{

    AuthorizationRef authRef = nil;
    AuthorizationRights authRights;
    AuthorizationEnvironment authEnvironment;
    AuthorizationItem authRightItems[1],
                      authEnvironmentItems[2];
    const char *usernameData = nil,
               *passwordData = nil;
    OSStatus authResult = 0;
    BOOL result = NO;
    
        NSParameterAssert(username && [username length]);
        NSParameterAssert(password);
    
    /* Set up our rights */
    
    authRightItems[0].name = "system.login.tty";
    authRightItems[0].value = nil;
    authRightItems[0].valueLength = 0;
    authRightItems[0].flags = 0;
    
    authRights.items = authRightItems;
    authRights.count = 1;
    
    /* Set up our environment */
    
    usernameData = [username GCSafeUTF8String];
    passwordData = [password GCSafeUTF8String];
    
    authEnvironmentItems[0].name = kAuthorizationEnvironmentUsername;
    authEnvironmentItems[0].value = (void *)usernameData;
    authEnvironmentItems[0].valueLength = strlen(usernameData);
    authEnvironmentItems[0].flags = 0;
    
    authEnvironmentItems[1].name = kAuthorizationEnvironmentPassword;
    authEnvironmentItems[1].value = (void *)passwordData;
    authEnvironmentItems[1].valueLength = strlen(passwordData);
    authEnvironmentItems[1].flags = 0;
    
    authEnvironment.items = authEnvironmentItems;
    authEnvironment.count = 2;
    
    authResult = AuthorizationCreate(&authRights, &authEnvironment, kAuthorizationFlagDefaults, &authRef);
    
        if (authResult != errAuthorizationSuccess || !authRef)
            goto cleanup;
    
    result = YES;
    
    cleanup:
    {
    
        if (authRef)
            AuthorizationFree(authRef, kAuthorizationFlagDefaults),
            authRef = nil;
    
    }
    
    return result;

}

@end