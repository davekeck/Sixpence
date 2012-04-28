#import <Foundation/Foundation.h>

/* ### This class is _not_ thread safe. It's meant to coordinate between separate processes, not threads.
   
   This class is meant to be a robust replacement for NSDistributedLock; the main difference being that
   an ALDL instance is guaranteed to be relinquished when the process exits, regardless of whether it
   crashed. */

@interface ALDistributedLock : NSObject
{

@private
    
    NSString *path;
    al_descriptor_t descriptor;

}

/* Creation */

- (id)initWithPath: (NSString *)newPath;

/* Properties */

@property(nonatomic, readonly, retain) NSString *path;

/* Methods */

- (BOOL)lockWithTimeout: (NSTimeInterval)timeout; /* Pass negative value for infinite timeout. */
- (BOOL)unlock;

@end