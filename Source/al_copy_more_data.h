#pragma once
#include <stdbool.h>
#include <sys/types.h>

/* Convenience macros for using _can_copy_more_data() and _copy_more_data() with buffers and scalars. */

#define al_cmd_can_copy_scalar_into_buffer(buffer_length, buffer_offset, scalar_length),         \
    al_cmd_can_copy_more_data(buffer_length, buffer_offset, scalar_length, 0, scalar_length)

#define al_cmd_copy_scalar_into_buffer(buffer, buffer_length, in_out_buffer_offset, scalar, scalar_length)             \
    al_cmd_copy_more_data(buffer, buffer_length, in_out_buffer_offset, scalar, scalar_length, NULL, scalar_length)

#define al_cmd_can_copy_buffer_into_scalar(scalar_length, buffer_length, buffer_offset)          \
    al_cmd_can_copy_more_data(scalar_length, 0, buffer_length, buffer_offset, scalar_length)

#define al_cmd_copy_buffer_into_scalar(scalar, scalar_length, buffer, buffer_length, in_out_buffer_offset)             \
    al_cmd_copy_more_data(scalar, scalar_length, NULL, buffer, buffer_length, in_out_buffer_offset, scalar_length)

/* _can_copy_more_data() returns false, unless the following four conditions are met:
   
     1. `copy_length` can be safely added to `destination_offset` without overflowing:
     
         (AL_INT_MAX_VALUE_FOR_OBJECT(destination_offset) - destination_offset) >= copy_length
     
     2. The range of data to be copied to the destination buffer lies completely within the remaining range of the destination buffer:
     
         (destination_offset + copy_length) <= destination_length
     
     3. `copy_length` can be safely added to `source_offset` without overflowing:
     
         (AL_INT_MAX_VALUE_FOR_OBJECT(source_offset) - source_offset) >= copy_length
     
     4. The range of data to be copied from the source buffer lies completely within the remaining range of the source buffer:
     
         (source_offset + copy_length) <= source_length

*/

bool al_cmd_can_copy_more_data(size_t destination_length, size_t destination_offset, size_t source_length, size_t source_offset, size_t copy_length);

/* This function is a safe way to copy `copy_length` bytes from the given offset within `source` into the given offset within `destination`.
   Argument assertions: `destination` and `source` must be non-NULL.
   
   `in_out_destination_offset` and `in_out_source_offset` can both be NULL. In either case, if the argument is NULL, then the offset within
   the respective buffer is assumed to be 0.
   
   This function performs the copy and returns true only if _can_copy_more_data() with the given arguments returns true. Otherwise, this
   function returns false and the copy is not attempted. */

bool al_cmd_copy_more_data(void *destination, size_t destination_length, size_t *in_out_destination_offset,
    const void *source, size_t source_length, size_t *in_out_source_offset, size_t copy_length);