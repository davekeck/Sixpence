#pragma once
#include <sys/types.h>
#include <stdbool.h>

char *al_base64_encode_data(const void *data, size_t data_length);
void *al_base64_decode_data(const char *string, size_t *data_length);