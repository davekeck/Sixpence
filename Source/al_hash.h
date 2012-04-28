#pragma once
#include <sys/types.h>

/* Type Definitions */

enum
{

    al_hash_hash_type_sha1,
    al_hash_hash_type_sha224,
    al_hash_hash_type_sha256,
    al_hash_hash_type_sha384,
    al_hash_hash_type_sha512,
    
    _al_hash_hash_type_length,
    _al_hash_hash_type_first = al_hash_hash_type_sha1

}; typedef int al_hash_hash_type;

/* Functions */

void *al_hash_data_hash(al_hash_hash_type hash_type, const void *data, size_t data_length);
char *al_hash_string_hash(al_hash_hash_type hash_type, const void *data, size_t data_length);

size_t al_hash_data_hash_length_for_hash_type(al_hash_hash_type hash_type);
size_t al_hash_string_hash_length_for_hash_type(al_hash_hash_type hash_type);