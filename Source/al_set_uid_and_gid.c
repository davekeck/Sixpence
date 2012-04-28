#include "al_set_uid_and_gid.h"

#include <unistd.h>

bool al_set_uid_and_gid(uid_t uid, gid_t gid)
{

    int setuid_result = 0;
    
    setuid_result = setgid(gid);
    
        AL_ASSERT_OR_PERFORM(!setuid_result, return false);
    
    setuid_result = setuid(uid);
    
        AL_ASSERT_OR_PERFORM(!setuid_result, return false);
    
    return true;

}