#pragma once
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <sys/sysctl.h>

struct kinfo_proc *al_plu_create_processes(size_t *out_processes_count);
bool al_plu_process_id_exists(pid_t process_id);
char *al_plu_short_process_name_for_process_id(pid_t process_id);
char *al_plu_full_process_name_for_process_id(pid_t process_id, bool fall_back);