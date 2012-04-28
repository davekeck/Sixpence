#pragma once

/* These are simple wrappers around the _NSGetArgv(), _NSGetArgc() and _NSGetEnviron() functions. */

char **al_argv(void);
int al_argc(void);
char **al_environ(void);