#include "al_base64.h"

#include <string.h>
#include <assert.h>
#include <openssl/bio.h>
#include <openssl/evp.h>

char *al_base64_encode_data(const void *data, size_t data_length)
{

    BIO *bio = NULL,
        *base64_bio = NULL;
    int write_result = 0;
    long temp_buffer_length = 0;
    bool return_result = false;
    char *temp_buffer = NULL,
         *result = NULL;
    
        /* Verify our arguments. Note that data == NULL is permitted only if data_length == 0. */
        
        assert(data || !data_length);
    
    /* Note that we allow data == NULL and/or data_length == 0. If either is the case, we'll simply
       return a zero-length string. */
    
    if (data && data_length)
    {
    
        bio = BIO_new(BIO_s_mem());
        
            AL_ASSERT_OR_PERFORM(bio, goto cleanup);
        
        base64_bio = BIO_new(BIO_f_base64());
        
            AL_ASSERT_OR_PERFORM(base64_bio, goto cleanup);
        
        BIO_set_flags(base64_bio, BIO_FLAGS_BASE64_NO_NL);
        bio = BIO_push(base64_bio, bio);
        
            AL_ASSERT_OR_PERFORM(bio, goto cleanup);
            
            /* Verify that our conversion from size_t to int is safe. */
            
            AL_ASSERT_OR_PERFORM(AL_INT_VALID_VALUE_FOR_OBJECT(data_length, int), goto cleanup);
        
        write_result = BIO_write(bio, data, (int)data_length);
        
            AL_ASSERT_OR_PERFORM(write_result == data_length, goto cleanup);
        
        (void)BIO_flush(bio);
        
        /* Note that temp_buffer_length is a 'long' because that's the return type of BIO_get_mem_data(). */
        
        temp_buffer_length = BIO_get_mem_data(bio, &temp_buffer);
        
            /* Verify that we got some output (which we must because we had some input, or else it's an error.) */
            
            AL_ASSERT_OR_PERFORM(temp_buffer && temp_buffer_length > 0, goto cleanup);
    
    }
    
        /* In the name of robustness, verify that our temp_buffer and temp_buffer_length variables agree. */
        
        AL_ASSERT_OR_PERFORM((temp_buffer && temp_buffer_length > 0) || (!temp_buffer && !temp_buffer_length), goto cleanup);
    
    /* ### Note that when we get here, we're guaranteed that either:
         
         o temp_buffer == NULL && temp_buffer_length == 0, or
         o temp_buffer != NULL && temp_buffer_length > 0. */
    
    /* Allocate enough space to hold temp_buffer, plus one for the NULL terminator. */
    
    result = malloc(temp_buffer_length + 1);
    
        AL_ASSERT_OR_PERFORM(result, goto cleanup);
    
    /* We're only attempting to copy temp_buffer into result if temp_buffer != NULL and temp_buffer_length > 0. (If data == NULL
       or data_length <= 0, we want to avoid trying to copy anything, since we didn't attempt and OpenSSL stuff, above, and
       we're just going to return a zero-length string. See the comment at the beginning of this function.)
       
       Note that we're not using strncpy() below, because the OpenSSL buffer isn't NULL-terminated. (Which of couse, we found
       out the hard way...) */
    
    if (temp_buffer && temp_buffer_length > 0)
        memcpy(result, temp_buffer, temp_buffer_length);
    
    /* Finally, terminate the result. */
    
    if (temp_buffer_length >= 0)
        result[temp_buffer_length] = 0;
    
    /* If we make it here, we succeeded! */
    
    return_result = true;
    
    cleanup:
    {
    
        if (result && !return_result)
            free(result),
            result = NULL;
        
        if (bio)
            BIO_free_all(bio),
            bio = NULL;
    
    }
    
    return result;

}

void *al_base64_decode_data(const char *string, size_t *data_length)
{

    static const size_t k_result_length_increment = 0x1000;
    size_t string_length = 0,
           result_length = 0,
           used_result_length = 0;
    BIO *bio = NULL,
        *base64_bio = NULL;
    bool return_result = false;
    void *result = NULL;
    
        /* Verify our arguments. Note that string == NULL is never allowed, but strlen(string) == 0 is. (If strlen(string) == 0,
           then we're simply going to return a non-NULL pointer, with *data_length = 0. */
        
        assert(string);
        assert(data_length);
    
    string_length = strlen(string);
    
    if (string_length)
    {
    
            /* Verify that our conversion from size_t to int is safe. */
            
            AL_ASSERT_OR_PERFORM(AL_INT_VALID_VALUE_FOR_OBJECT(string_length, int), goto cleanup);
        
        /* We're only going to attempt this OpenSSL goodness if we have a base 64 string to do it on. Otherwise, if strlen(string) == 0,
           then we're just going to return a pointer to a zero-length block of data. */
        
        bio = BIO_new_mem_buf((void *)string, (int)string_length);
        
            AL_ASSERT_OR_PERFORM(bio, goto cleanup);
        
        base64_bio = BIO_new(BIO_f_base64());
        
            AL_ASSERT_OR_PERFORM(base64_bio, goto cleanup);
        
        BIO_set_flags(base64_bio, BIO_FLAGS_BASE64_NO_NL);
        bio = BIO_push(base64_bio, bio);
        
            AL_ASSERT_OR_PERFORM(bio, goto cleanup);
        
        /* Loop until we've read all the available data. */
        
        for (;;)
        {
        
            int read_result = 0;
            
            if (result_length <= used_result_length)
            {
            
                result_length += k_result_length_increment;
                
                result = reallocf(result, result_length);
                
                    AL_ASSERT_OR_PERFORM(result, goto cleanup);
            
            }
            
                /* Verify that our conversion from size_t to int is safe. */
                
                AL_ASSERT_OR_PERFORM(AL_INT_VALID_VALUE_FOR_OBJECT(result_length, int), goto cleanup);
            
            read_result = BIO_read(bio, (result + used_result_length), (int)(result_length - used_result_length));
            
                if (read_result <= 0)
                    break;
            
            used_result_length += read_result;
        
        }
        
            /* Since string_length > 0, then our output data must be > 0. If that's not the case, then we're failing. */
            
            AL_ASSERT_OR_PERFORM(used_result_length, goto cleanup);
        
        /* Now that we're finished reading, the 'real' result length is the length that's actually occupied in the buffer. */
        
        result_length = used_result_length;
    
    }
    
    /* Adjust our result length so it's never zero. This is necessary so that we don't reallocf() (below) with a zero size;
       if we did, we'd risk returning NULL, which is reserved for errors. */
    
    if (!result_length)
        result_length = 1;
    
    /* ### Note that when we arrive here, used_result_length may == 0. And if it does, it's all good, because we permit input
           strings of zero length.
       
       Now we'll resize the output buffer so that it only takes up the space it needs (the loop above will usually
       exit with result having excess space in the buffer.) */
    
    result = reallocf(result, result_length);
    
        AL_ASSERT_OR_PERFORM(result, goto cleanup);
    
    /* Note that *data_length = used_result_length, _NOT_ *data_length = result_length. This is because we adjust result_length
       to be a minimum of 1; ie, used_result_length holds the size that the caller is interested in, where as result_length
       holds result's true available size that we malloc'd.
       
       Also note that we 'assert(data_length)' earlier, so no need for 'if (data_length)'. */
    
    *data_length = used_result_length;
    
    return_result = true;
    
    cleanup:
    {
    
        if (result && !return_result)
            free(result),
            result = NULL;
        
        if (bio)
            BIO_free_all(bio),
            bio = NULL;
    
    }
    
    return result;

}