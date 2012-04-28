#pragma once
#include <stdbool.h>
#include <sys/types.h>

#pragma mark Definitions
#pragma mark -

#define al_descriptor_init al_descriptor_create(false, 0)
#define al_pid_init al_pid_create(false, 0)
#define al_uid_init al_uid_create(false, 0)
#define al_gid_init al_gid_create(false, 0)

#pragma mark Type Definitions
#pragma mark -

typedef struct al_descriptor_t
{

    bool valid;
    int descriptor;

} al_descriptor_t;

typedef struct al_pid_t
{

    bool valid;
    pid_t pid;

} al_pid_t;

typedef struct al_uid_t
{

    bool valid;
    uid_t uid;

} al_uid_t;

typedef struct al_gid_t
{

    bool valid;
    gid_t gid;

} al_gid_t;

#pragma mark -
#pragma mark Functions
#pragma mark -

static inline al_descriptor_t al_descriptor_create(bool valid, int descriptor)
{

    al_descriptor_t result;
    
    result.valid = valid;
    result.descriptor = descriptor;
    
    return result;

}

#define al_descriptor_cleanup(descriptor_pointer, error_action)        \
({                                                                     \
                                                                       \
        assert(descriptor_pointer);                                    \
                                                                       \
    if ((descriptor_pointer)->valid)                                   \
    {                                                                  \
                                                                       \
        int __close_result = 0;                                        \
                                                                       \
        __close_result = close((descriptor_pointer)->descriptor),      \
        (descriptor_pointer)->valid = false;                           \
                                                                       \
            AL_ASSERT_OR_PERFORM(!__close_result, error_action);       \
                                                                       \
    }                                                                  \
                                                                       \
})

static inline al_pid_t al_pid_create(bool valid, pid_t pid)
{

    al_pid_t result;
    
    result.valid = valid;
    result.pid = pid;
    
    return result;

}

static inline al_uid_t al_uid_create(bool valid, uid_t uid)
{

    al_uid_t result;
    
    result.valid = valid;
    result.uid = uid;
    
    return result;

}

static inline al_gid_t al_gid_create(bool valid, gid_t gid)
{

    al_gid_t result;
    
    result.valid = valid;
    result.gid = gid;
    
    return result;

}