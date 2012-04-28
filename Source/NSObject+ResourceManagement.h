#import <Foundation/Foundation.h>

@interface NSObject (ResourceManagement)

/* These methods retain the reciver so that it will not be released until all resources have a 0 retain count (and
   therefore -cleanupResource: has been called for all resources.) */

- (void)retainResource: (void *)resource;
- (void)releaseResource: (void *)resource;

/* You must call super's implementation of this method if you don't recognize 'resource'. */

- (void)cleanupResource: (void *)resource;

@end