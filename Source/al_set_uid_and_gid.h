#pragma once
#include <stdbool.h>
#include <pwd.h>
#include <grp.h>

bool al_set_uid_and_gid(uid_t uid, gid_t gid);