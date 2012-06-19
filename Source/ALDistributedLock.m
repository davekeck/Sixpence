// Garbage Collection
//   o implemented simple error-checking -finalize
//   o verified uses of &

#import "ALDistributedLock.h"

#import <sys/stat.h>

#import "al_modify_descriptor_flags.h"

#pragma mark Static Variables
#pragma mark -

/* This dictionary maps between paths (NSStrings) => a lock (ALDistributedLock). */

static NSMapTable *ALDistributedLock_Locks = nil;

#pragma mark Property Redeclarations
#pragma mark -

@interface ALDistributedLock ()

@property(nonatomic, readwrite, retain) NSString *path;

@end

#pragma mark -
#pragma mark Private Method Interfaces
#pragma mark -

@interface ALDistributedLock (Private)

#pragma mark -

- (BOOL)tryLockAndWait: (BOOL)waitForLock locked: (BOOL *)outLocked;

@end

#pragma mark -

@implementation ALDistributedLock

#pragma mark -
#pragma mark Creation
#pragma mark -

+ (void)initialize
{

        /* Because a class' +initialize method can be called more than once, we need to make
           sure it's being called for us, specifically. */
        
        ALConfirmOrPerform(self == [ALDistributedLock class], return);
    
    ALDistributedLock_Locks = [[NSMapTable mapTableWithStrongToWeakObjects] retain];

}

- (id)initWithPath: (NSString *)newPath
{

    ALDistributedLock *existingLock = nil;
    
        NSParameterAssert(newPath && [newPath length]);
    
    if (!(self = [super init]))
        return nil;
    
    /* This needs to occur before we check for an existing lock, because the [self release] => dealloc => requires descriptor < 0. */
    
    [self setPath: newPath];
    descriptor = al_descriptor_init;
    
    /* Check if we already have a lock for the given path. If so, then we want to return that lock, not the receiver. */
    
    existingLock = [ALDistributedLock_Locks objectForKey: newPath];
    
    if (existingLock)
    {
    
        /* Retain the result, since the caller expects it. */
        
        [existingLock retain];
        [self release];
        
        return existingLock;
    
    }
    
    /* Otherwise, if we make it here, then the receiver is unique, so we'll register it in our global array. */
    
    [ALDistributedLock_Locks setObject: self forKey: path];
    
    return self;

}

- (void)dealloc
{

        ALAssertOrRaise(!descriptor.valid);
    
    if (path && [ALDistributedLock_Locks objectForKey: path] == self)
        [ALDistributedLock_Locks removeObjectForKey: path];
    
    [self setPath: nil];
    [super dealloc];

}

- (void)finalize
{

        ALAssertOrRaise(!descriptor.valid);
    
    [super finalize];

}

#pragma mark -
#pragma mark Properties
#pragma mark -

@synthesize path;

#pragma mark Methods
#pragma mark -

- (BOOL)lockWithTimeout: (NSTimeInterval)timeout
{

    static const NSTimeInterval kDelayBetweenLockAttempts = 0.001;
    double startTime = 0.0;
    
    /* Mark our starting time before we start attempting to acquire a lock. */
    
    startTime = al_time_current_time();
    
    for (;;)
    {
    
        BOOL tryLockAndWaitResult = NO,
             locked = NO;
        
        tryLockAndWaitResult = [self tryLockAndWait: (timeout >= 0.0 ? NO : YES) locked: &locked];
        
            ALAssertOrPerform(tryLockAndWaitResult, return NO);
            
            if (locked)
                return YES;
            
            ALConfirmOrPerform(!al_time_timeout_has_elapsed(startTime, timeout), return NO);
        
        [NSThread sleepForTimeInterval: kDelayBetweenLockAttempts];
    
    }
    
    return NO;

}

- (BOOL)unlock
{

        ALAssertOrRaise(descriptor.valid);
    
    /* Close the file descriptor, which implicitly relinquishes the lock. */
    
    al_descriptor_cleanup(&descriptor, return NO);
    
    return YES;

}

//- (BOOL)locked: (BOOL *)outLocked
//{
//
//    const char *pathFileSystemRepresentation = nil;
//    struct flock flock;
//    int tempdescriptor = 0,
//        fcntlResult = 0;
//    BOOL locked = NO,
//         setCloseOnExecResult = NO,
//         result = NO;
//    
//        NSParameterAssert(outLocked);
//    
//    /* Initialize our variables. */
//    
//    tempdescriptor = -1;
//    
//        /* If descriptor >= 0, then we hold the lock, so of course we want to return YES.
//           
//           ### This is necessary because the first close() of the file descriptor (from the process that owns the lock) with a lock attached
//               will release the lock (the open()'s and close()'s aren't stacked). Therefore, if we didn't check whether we owned the lock
//               and simply executed this method, we would open() then subsequently close() the lock, so the lock would always end up being
//               relinquished when this method returned (that is, if this process owned the lock.) */
//        
//        ALConfirmOrPerform(descriptor < 0, locked = YES; goto successCleanup);
//    
//    pathFileSystemRepresentation = [path fileSystemRepresentation];
//    
//    /* Open the lock file so we can fcntl() it. */
//    
//    errno = 0;
//    tempdescriptor = open(pathFileSystemRepresentation, (O_RDONLY | O_NONBLOCK));
//    
//        /* If we couldn't open the file because it doesn't exist (errno == ENOENT), then we were successful (and the lock's unlocked!) */
//        
//        ALAssertOrPerform(tempdescriptor >= 0 || (tempdescriptor == -1 && errno == ENOENT), goto cleanup);
//        ALConfirmOrPerform(tempdescriptor >= 0, goto successCleanup);
//    
//    setCloseOnExecResult = al_mdf_set_descriptor_close_on_exec(tempdescriptor, YES);
//    
//        ALAssertOrPerform(setCloseOnExecResult, goto cleanup);
//    
//    flock.l_type = F_WRLCK;
//    flock.l_whence = SEEK_SET;
//    flock.l_start = 0;
//    flock.l_len = 0;
//    flock.l_pid = getpid();
//    
//    /* Ask fcntl if there's a lock on the file. */
//    
//    fcntlResult = fcntl(tempdescriptor, F_GETLK, &flock);
//    
//        /* Note that we're checking fcntlResult specifically for -1, as the man page specifies other values may be returned, but only -1
//           represents an error. Additionally, the man page states .l_whence == SEEK_SET on success. */
//        
//        ALAssertOrPerform(fcntlResult != -1 && flock.l_whence == SEEK_SET, goto cleanup);
//    
//    locked = (flock.l_type != F_UNLCK);
//    
//    successCleanup:
//    {
//    
//        /* If we make it here, we succeeded! */
//        
//        result = YES;
//    
//    }
//    
//    cleanup:
//    {
//    
//        if (tempdescriptor >= 0)
//        {
//        
//            int closeResult = 0;
//            
//            closeResult = close(tempdescriptor),
//            tempdescriptor = -1;
//            
//                ALAssertOrPerform(!closeResult, result = NO);
//        
//        }
//        
//        /* Fill our output variables. */
//        
//        if (result)
//            *outLocked = locked;
//    
//    }
//    
//    return result;
//
//}

#pragma mark -
#pragma mark Private Method Implementations
#pragma mark -

- (BOOL)tryLockAndWait: (BOOL)waitForLock locked: (BOOL *)outLocked
{

    const char *pathFileSystemRepresentation = nil;
    struct stat lockFileInfo;
    int lstatResult = 0;
    BOOL setCloseOnExecResult = NO,
         locked = NO,
         result = NO;
    
        NSParameterAssert(outLocked);
        ALAssertOrRaise(!descriptor.valid);
    
    pathFileSystemRepresentation = [path fileSystemRepresentation];
    
    /* This operation will both atomically create our lock file and aquire the lock. */
    
    errno = 0;
    descriptor.descriptor = open(pathFileSystemRepresentation, (O_RDWR | (waitForLock ? 0 : O_NONBLOCK) | O_CREAT | O_EXLOCK),
        ((S_IRUSR | S_IWUSR | S_IXUSR) | (S_IRGRP | S_IWGRP | S_IXGRP) | (S_IROTH | S_IWOTH | S_IXOTH))),
    descriptor.valid = (descriptor.descriptor != -1);
    
        ALAssertOrPerform(descriptor.valid || (!descriptor.valid && errno == EAGAIN), goto cleanup);
        ALConfirmOrPerform(descriptor.valid, goto successCleanup);
    
    /* Verify that the lock file exists. If it doesn't then we were more than likely trying to acquire the lock while another process
       had the lock. So when they released the lock, they deleted the file. But yet, in this scenario, (through empirical evidence)
       we're still able to open the file descriptor, despite the fact that it's no longer linked on disk. Therefore, we have to check
       whether the file still exists. If it doesn't, we have to start over. If it does, we acquired the lock successfully and can
       move on. */
    
    lstatResult = lstat(pathFileSystemRepresentation, &lockFileInfo);
    
        ALAssertOrPerform(!lstatResult, goto cleanup);
        ALAssertOrPerform(S_ISREG(lockFileInfo.st_mode), goto cleanup);
    
    /* We're only attempting to change the permissions of the lock file if we own it, or if we're the superuser. These are the only
       two conditions in which fchmod will succeed. */
    
    if (lockFileInfo.st_uid == geteuid() || !getuid())
    {
    
        int fchmodResult = 0;
        
        /* Make the lock file accessible by anyone. */
        
        fchmodResult = fchmod(descriptor.descriptor, ((S_IRUSR | S_IWUSR | S_IXUSR) | (S_IRGRP | S_IWGRP | S_IXGRP) | (S_IROTH | S_IWOTH | S_IXOTH)));
        
            ALAssertOrPerform(!fchmodResult, goto cleanup);
    
    }
    
    setCloseOnExecResult = al_mdf_set_descriptor_close_on_exec(descriptor.descriptor, YES);
    
        ALAssertOrPerform(setCloseOnExecResult, goto cleanup);
    
    locked = YES;
    
    successCleanup:
    {
    
        result = YES;
    
    }
    
    cleanup:
    {
    
        if ((!result || !locked) && descriptor.valid)
            al_descriptor_cleanup(&descriptor, result = NO);
        
        /* Fill our output variables. */
        
        if (result)
            *outLocked = locked;
    
    }
    
    return result;

}

@end