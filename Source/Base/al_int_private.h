#pragma once

/* These macros should not be used by third parties. */
/* These macros expect that (1) arguments are variables in a wrapper macro, and (2) arguments' types are integer types. */

#define AL_INT_PRIVATE_VALID_VALUE_FOR_TYPE(value, type)                                                             \
({                                                                                                                   \
                                                                                                                     \
    AL_VALUE_IN_RANGE(value, AL_INT_PRIVATE_MIN_VALUE_FOR_TYPE(type), AL_INT_PRIVATE_MAX_VALUE_FOR_TYPE(type));      \
                                                                                                                     \
})

#define AL_INT_PRIVATE_MIN_VALUE_FOR_TYPE(type)                                                                 \
({                                                                                                              \
                                                                                                                \
    (type)(AL_INT_PRIVATE_TYPE_CAN_BE_NEGATIVE(type) ? (-((uintmax_t)1 << ((sizeof(type) * 8) - 1))) : 0);      \
                                                                                                                \
})

#define AL_INT_PRIVATE_MAX_VALUE_FOR_TYPE(type)                                                                           \
({                                                                                                                        \
                                                                                                                          \
    (type)(((((uintmax_t)1 << ((sizeof(type) * 8) - 1)) - 1) *                                                            \
        (AL_INT_PRIVATE_TYPE_CAN_BE_NEGATIVE(type) ? 1 : 2)) + (AL_INT_PRIVATE_TYPE_CAN_BE_NEGATIVE(type) ? 0 : 1));      \
                                                                                                                          \
})

#define AL_INT_PRIVATE_TYPE_CAN_BE_NEGATIVE(type)                                                                        \
({                                                                                                                       \
                                                                                                                         \
    ((__builtin_types_compatible_p(type, signed char) || (__builtin_types_compatible_p(type, char) && CHAR_MIN)) ||      \
    __builtin_types_compatible_p(type, short) ||                                                                         \
    __builtin_types_compatible_p(type, int) ||                                                                           \
    __builtin_types_compatible_p(type, long) ||                                                                          \
    __builtin_types_compatible_p(type, long long));                                                                      \
                                                                                                                         \
})

#define AL_INT_PRIVATE_GREATER_THAN(a, b)                      \
({                                                             \
                                                               \
    ((a >= 0 && b >= 0) ? ((uintmax_t)a > (uintmax_t)b) :      \
    ((a < 0 && b < 0) ?   ((intmax_t)a > (intmax_t)b) :        \
                          (a >= 0 && b < 0)));                 \
                                                               \
})

#define AL_INT_PRIVATE_GREATER_THAN_OR_EQUAL(a, b)              \
({                                                              \
                                                                \
    ((a >= 0 && b >= 0) ? ((uintmax_t)a >= (uintmax_t)b) :      \
    ((a < 0 && b < 0) ?   ((intmax_t)a >= (intmax_t)b) :        \
                          (a >= 0 && b < 0)));                  \
                                                                \
})

#define AL_INT_PRIVATE_LESS_THAN(a, b) AL_INT_PRIVATE_GREATER_THAN(b, a)
#define AL_INT_PRIVATE_LESS_THAN_OR_EQUAL(a, b) AL_INT_PRIVATE_GREATER_THAN_OR_EQUAL(b, a)