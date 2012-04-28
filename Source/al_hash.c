#include "al_hash.h"

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <assert.h>

#include <CommonCrypto/CommonDigest.h>

#pragma mark Type Definitions
#pragma mark -

typedef unsigned char *(* al_hash_hash_function)(const void *, CC_LONG, unsigned char *);

#pragma mark -
#pragma mark Private Constants
#pragma mark -

static const al_hash_hash_function al_hash_hash_functions[] =
{
    [al_hash_hash_type_sha1] = CC_SHA1,
    [al_hash_hash_type_sha224] = CC_SHA224,
    [al_hash_hash_type_sha256] = CC_SHA256,
    [al_hash_hash_type_sha384] = CC_SHA384,
    [al_hash_hash_type_sha512] = CC_SHA512
};

static const size_t al_hash_data_hash_lengths[] =
{
    [al_hash_hash_type_sha1] = CC_SHA1_DIGEST_LENGTH,
    [al_hash_hash_type_sha224] = CC_SHA224_DIGEST_LENGTH,
    [al_hash_hash_type_sha256] = CC_SHA256_DIGEST_LENGTH,
    [al_hash_hash_type_sha384] = CC_SHA384_DIGEST_LENGTH,
    [al_hash_hash_type_sha512] = CC_SHA512_DIGEST_LENGTH
};

#pragma mark Public Function Implementations
#pragma mark -

void *al_hash_data_hash(al_hash_hash_type hash_type, const void *data, size_t data_length)
{

    unsigned char *hash_function_result = NULL;
    void *result = NULL;
    
        assert(AL_VALUE_IN_RANGE_EXCLUSIVE(hash_type, _al_hash_hash_type_first, _al_hash_hash_type_length));
        assert(data || !data_length);
    
    result = malloc(al_hash_data_hash_length_for_hash_type(hash_type));
    
        AL_ASSERT_OR_PERFORM(result, goto failed);
        
        /* Verify that our conversion from size_t to CC_LONG is safe. */
        
        AL_ASSERT_OR_PERFORM(AL_INT_VALID_VALUE_FOR_OBJECT(data_length, CC_LONG), goto failed);
    
    hash_function_result = al_hash_hash_functions[hash_type](data, (CC_LONG)data_length, result);
    
        AL_ASSERT_OR_PERFORM(hash_function_result == result, goto failed);
    
    return result;
    
    failed:
    {
    
        if (result)
            free(result),
            result = NULL;
    
    }
    
    return NULL;

}

char *al_hash_string_hash(al_hash_hash_type hash_type, const void *data, size_t data_length)
{

    size_t hash_data_length = 0,
           i = 0;
    void *hash_data = NULL;
    bool return_result = false;
    char *result = NULL;
    
        assert(AL_VALUE_IN_RANGE_EXCLUSIVE(hash_type, _al_hash_hash_type_first, _al_hash_hash_type_length));
        assert(data || !data_length);
    
    hash_data = al_hash_data_hash(hash_type, data, data_length);
    
        AL_ASSERT_OR_PERFORM(hash_data, goto cleanup);
    
    /* Adding one for the NULL terminator. */
    
    result = malloc(al_hash_string_hash_length_for_hash_type(hash_type) + 1);
    
        AL_ASSERT_OR_PERFORM(hash_data, goto cleanup);
    
    hash_data_length = al_hash_data_hash_length_for_hash_type(hash_type);
    
    for (i = 0; i < hash_data_length; i++)
    {
    
        int snprintf_result = 0;
        
        snprintf_result = snprintf(&result[i * 2], 3, "%02x", ((unsigned char *)hash_data)[i]);
        
            AL_ASSERT_OR_PERFORM(snprintf_result == 2, goto cleanup);
    
    }
    
    /* snprintf() automatically terminates the result. */
    
    return_result = true;
    
    cleanup:
    {
    
        if (result && !return_result)
            free(result),
            result = NULL;
        
        if (hash_data)
            free(hash_data),
            hash_data = NULL;
    
    }
    
    return result;

}

size_t al_hash_data_hash_length_for_hash_type(al_hash_hash_type hash_type)
{

        assert(AL_VALUE_IN_RANGE_EXCLUSIVE(hash_type, _al_hash_hash_type_first, _al_hash_hash_type_length));
    
    return al_hash_data_hash_lengths[hash_type];

}

size_t al_hash_string_hash_length_for_hash_type(al_hash_hash_type hash_type)
{

        assert(AL_VALUE_IN_RANGE_EXCLUSIVE(hash_type, _al_hash_hash_type_first, _al_hash_hash_type_length));
    
    /* A byte represented in hex will takes two characters... */
    
    return (2 * al_hash_data_hash_lengths[hash_type]);

}