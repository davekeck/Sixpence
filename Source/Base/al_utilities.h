#pragma once
#include <TargetConditionals.h>
#include "al_int_private.h"

#if (!defined(KERNEL) || !KERNEL)

    #include <limits.h>

#else

    #include <machine/limits.h>

#endif

/* Definitions */

#define AL_STRINGIFY(a) #a
#define AL_EVALUATED_STRINGIFY(a) AL_STRINGIFY(a)

#define AL_EQUAL_BOOLS(a, b) ((bool)(a) == (bool)(b))
#define AL_VAR(a, b) ___##a##_##b

#define AL_MIN(a, b)                                                                                                  \
({                                                                                                                    \
                                                                                                                      \
    __typeof__(a) AL_VAR(AL_MIN, x) = (a);                                                                            \
    __typeof__(b) AL_VAR(AL_MIN, y) = (b);                                                                            \
                                                                                                                      \
        AL_COMPILER_ASSERT(AL_COMPATIBLE_SCALAR_TYPES(__typeof__(a), __typeof__(b)));                                 \
                                                                                                                      \
    AL_COMPILER_IF(AL_INT_TYPE(__typeof__(a)))                                                                        \
                                                                                                                      \
        /* Integer types */                                                                                           \
                                                                                                                      \
        (AL_INT_PRIVATE_LESS_THAN(AL_VAR(AL_MIN, x), AL_VAR(AL_MIN, y)) ? AL_VAR(AL_MIN, x) : AL_VAR(AL_MIN, y))      \
                                                                                                                      \
    AL_COMPILER_ELSE()                                                                                                \
                                                                                                                      \
        /* Floating-point types */                                                                                    \
                                                                                                                      \
        (AL_VAR(AL_MIN, x) < AL_VAR(AL_MIN, y) ? AL_VAR(AL_MIN, x) : AL_VAR(AL_MIN, y))                               \
                                                                                                                      \
    AL_COMPILER_END_IF();                                                                                             \
                                                                                                                      \
})

#define AL_MAX(a, b)                                                                                                     \
({                                                                                                                       \
                                                                                                                         \
    __typeof__(a) AL_VAR(AL_MAX, x) = (a);                                                                               \
    __typeof__(b) AL_VAR(AL_MAX, y) = (b);                                                                               \
                                                                                                                         \
        AL_COMPILER_ASSERT(AL_COMPATIBLE_SCALAR_TYPES(__typeof__(a), __typeof__(b)));                                    \
                                                                                                                         \
    AL_COMPILER_IF(AL_INT_TYPE(__typeof__(a)))                                                                           \
                                                                                                                         \
        /* Integer types */                                                                                              \
                                                                                                                         \
        (AL_INT_PRIVATE_GREATER_THAN(AL_VAR(AL_MAX, x), AL_VAR(AL_MAX, y)) ? AL_VAR(AL_MAX, x) : AL_VAR(AL_MAX, y))      \
                                                                                                                         \
    AL_COMPILER_ELSE()                                                                                                   \
                                                                                                                         \
        /* Floating-point types */                                                                                       \
                                                                                                                         \
        (AL_VAR(AL_MAX, x) > AL_VAR(AL_MAX, y) ? AL_VAR(AL_MAX, x) : AL_VAR(AL_MAX, y))                                  \
                                                                                                                         \
    AL_COMPILER_END_IF();                                                                                                \
                                                                                                                         \
})

#define AL_CAP_MIN AL_MAX
#define AL_CAP_MAX AL_MIN

#define AL_CAP_RANGE(value, min, max)                                                                                                                                                                  \
({                                                                                                                                                                                                     \
                                                                                                                                                                                                       \
    __typeof__(value) AL_VAR(AL_CAP_RANGE, x) = (value);                                                                                                                                               \
    __typeof__(min) AL_VAR(AL_CAP_RANGE, y) = (min);                                                                                                                                                   \
    __typeof__(max) AL_VAR(AL_CAP_RANGE, z) = (max);                                                                                                                                                   \
                                                                                                                                                                                                       \
        AL_COMPILER_ASSERT(AL_COMPATIBLE_SCALAR_TYPES(__typeof__(value), __typeof__(min)));                                                                                                            \
        AL_COMPILER_ASSERT(AL_COMPATIBLE_SCALAR_TYPES(__typeof__(min), __typeof__(max)));                                                                                                              \
                                                                                                                                                                                                       \
    AL_COMPILER_IF(AL_INT_TYPE(__typeof__(value)))                                                                                                                                                     \
                                                                                                                                                                                                       \
        /* Integer types */                                                                                                                                                                            \
                                                                                                                                                                                                       \
        (AL_INT_PRIVATE_GREATER_THAN_OR_EQUAL(AL_VAR(AL_CAP_RANGE, x), AL_VAR(AL_CAP_RANGE, y)) ?                                                                                                      \
            (AL_INT_PRIVATE_LESS_THAN_OR_EQUAL(AL_VAR(AL_CAP_RANGE, x), AL_VAR(AL_CAP_RANGE, z)) ? AL_VAR(AL_CAP_RANGE, x) : AL_VAR(AL_CAP_RANGE, z)) : AL_VAR(AL_CAP_RANGE, y))                       \
                                                                                                                                                                                                       \
    AL_COMPILER_ELSE()                                                                                                                                                                                 \
                                                                                                                                                                                                       \
        /* Floating-point types */                                                                                                                                                                     \
                                                                                                                                                                                                       \
        (AL_VAR(AL_CAP_RANGE, x) >= AL_VAR(AL_CAP_RANGE, y) ? (AL_VAR(AL_CAP_RANGE, x) <= AL_VAR(AL_CAP_RANGE, z) ? AL_VAR(AL_CAP_RANGE, x) : AL_VAR(AL_CAP_RANGE, z)) : AL_VAR(AL_CAP_RANGE, y))      \
                                                                                                                                                                                                       \
    AL_COMPILER_END_IF();                                                                                                                                                                              \
                                                                                                                                                                                                       \
})

#define AL_VALUE_IN_RANGE(value, min, max)                                                                                                                                                                     \
({                                                                                                                                                                                                             \
                                                                                                                                                                                                               \
    __typeof__(value) AL_VAR(AL_VALUE_IN_RANGE, x) = (value);                                                                                                                                                  \
    __typeof__(min) AL_VAR(AL_VALUE_IN_RANGE, y) = (min);                                                                                                                                                      \
    __typeof__(max) AL_VAR(AL_VALUE_IN_RANGE, z) = (max);                                                                                                                                                      \
                                                                                                                                                                                                               \
        AL_COMPILER_ASSERT(AL_COMPATIBLE_SCALAR_TYPES(__typeof__(value), __typeof__(min)));                                                                                                                    \
        AL_COMPILER_ASSERT(AL_COMPATIBLE_SCALAR_TYPES(__typeof__(min), __typeof__(max)));                                                                                                                      \
                                                                                                                                                                                                               \
    AL_COMPILER_IF(AL_INT_TYPE(__typeof__(value)))                                                                                                                                                             \
                                                                                                                                                                                                               \
        /* Integer types */                                                                                                                                                                                    \
                                                                                                                                                                                                               \
        AL_INT_PRIVATE_GREATER_THAN_OR_EQUAL(AL_VAR(AL_VALUE_IN_RANGE, x), AL_VAR(AL_VALUE_IN_RANGE, y)) && AL_INT_PRIVATE_LESS_THAN_OR_EQUAL(AL_VAR(AL_VALUE_IN_RANGE, x), AL_VAR(AL_VALUE_IN_RANGE, z))      \
                                                                                                                                                                                                               \
    AL_COMPILER_ELSE()                                                                                                                                                                                         \
                                                                                                                                                                                                               \
        /* Floating-point types */                                                                                                                                                                             \
                                                                                                                                                                                                               \
        (AL_VAR(AL_VALUE_IN_RANGE, x) >= AL_VAR(AL_VALUE_IN_RANGE, y) && AL_VAR(AL_VALUE_IN_RANGE, x) <= AL_VAR(AL_VALUE_IN_RANGE, z))                                                                         \
                                                                                                                                                                                                               \
    AL_COMPILER_END_IF();                                                                                                                                                                                      \
                                                                                                                                                                                                               \
})

#define AL_VALUE_IN_RANGE_EXCLUSIVE(value, min, max)                                                                                                                               \
({                                                                                                                                                                                 \
                                                                                                                                                                                   \
    __typeof__(value) AL_VAR(AL_VALUE_IN_RANGE_EXCLUSIVE, x) = (value);                                                                                                            \
    __typeof__(min) AL_VAR(AL_VALUE_IN_RANGE_EXCLUSIVE, y) = (min);                                                                                                                \
    __typeof__(max) AL_VAR(AL_VALUE_IN_RANGE_EXCLUSIVE, z) = (max);                                                                                                                \
                                                                                                                                                                                   \
        AL_COMPILER_ASSERT(AL_COMPATIBLE_SCALAR_TYPES(__typeof__(value), __typeof__(min)));                                                                                        \
        AL_COMPILER_ASSERT(AL_COMPATIBLE_SCALAR_TYPES(__typeof__(min), __typeof__(max)));                                                                                          \
                                                                                                                                                                                   \
    AL_COMPILER_IF(AL_INT_TYPE(__typeof__(value)))                                                                                                                                 \
                                                                                                                                                                                   \
        /* Integer types */                                                                                                                                                        \
                                                                                                                                                                                   \
        AL_INT_PRIVATE_GREATER_THAN_OR_EQUAL(AL_VAR(AL_VALUE_IN_RANGE_EXCLUSIVE, x), AL_VAR(AL_VALUE_IN_RANGE_EXCLUSIVE, y)) &&                                                    \
            AL_INT_PRIVATE_LESS_THAN(AL_VAR(AL_VALUE_IN_RANGE_EXCLUSIVE, x), AL_VAR(AL_VALUE_IN_RANGE_EXCLUSIVE, z))                                                               \
                                                                                                                                                                                   \
    AL_COMPILER_ELSE()                                                                                                                                                             \
                                                                                                                                                                                   \
        /* Floating-point types */                                                                                                                                                 \
                                                                                                                                                                                   \
        (AL_VAR(AL_VALUE_IN_RANGE_EXCLUSIVE, x) >= AL_VAR(AL_VALUE_IN_RANGE_EXCLUSIVE, y) && AL_VAR(AL_VALUE_IN_RANGE_EXCLUSIVE, x) < AL_VAR(AL_VALUE_IN_RANGE_EXCLUSIVE, z))      \
                                                                                                                                                                                   \
    AL_COMPILER_END_IF();                                                                                                                                                          \
                                                                                                                                                                                   \
})

#define AL_FILL_STATIC_ARRAY(array, ...)                                    \
({                                                                          \
                                                                            \
    __typeof__(array) AL_VAR(AL_FILL_STATIC_ARRAY, x) = {__VA_ARGS__};      \
    memcpy(&array, AL_VAR(AL_FILL_STATIC_ARRAY, x), sizeof(array));         \
                                                                            \
})

#define AL_STATIC_ARRAY_COUNT(array) (sizeof(array) / sizeof(*array))

#define AL_CONFIRM_OR_PERFORM(condition, action)      \
({                                                    \
                                                      \
    if (!(condition))                                 \
    {                                                 \
                                                      \
        action;                                       \
                                                      \
    }                                                 \
                                                      \
})

#define AL_COMPILER_IF(a) __builtin_choose_expr((a), (
#define AL_COMPILER_ELSE() ),
#define AL_COMPILER_END_IF() )
#define AL_COMPILER_TYPES_COMPATIBLE(a, y) __builtin_types_compatible_p(a, y)
#define AL_COMPILER_ASSERT(assertion)                                                  \
({                                                                                     \
                                                                                       \
    int AL_VAR(AL_COMPILER_ASSERT, x)[__builtin_choose_expr((assertion), 0, -1)];      \
    (void)(AL_VAR(AL_COMPILER_ASSERT, x));                                             \
                                                                                       \
})

#define AL_INT_TYPE(type)                                                                                                                                        \
    (AL_COMPILER_TYPES_COMPATIBLE(type, char) ||                                                                                                                 \
    AL_COMPILER_TYPES_COMPATIBLE(type, signed char) ||                                                                                                           \
    AL_COMPILER_TYPES_COMPATIBLE(type, unsigned char) ||                                                                                                         \
                                                                                                                                                                 \
    AL_COMPILER_TYPES_COMPATIBLE(type, signed short) ||                                                                                                          \
    AL_COMPILER_TYPES_COMPATIBLE(type, unsigned short) ||                                                                                                        \
                                                                                                                                                                 \
    AL_COMPILER_TYPES_COMPATIBLE(type, signed int) ||                                                                                                            \
    AL_COMPILER_TYPES_COMPATIBLE(type, unsigned int) ||                                                                                                          \
                                                                                                                                                                 \
    AL_COMPILER_TYPES_COMPATIBLE(type, signed long) ||                                                                                                           \
    AL_COMPILER_TYPES_COMPATIBLE(type, unsigned long) ||                                                                                                         \
                                                                                                                                                                 \
    AL_COMPILER_TYPES_COMPATIBLE(type, signed long long) ||                                                                                                      \
    AL_COMPILER_TYPES_COMPATIBLE(type, unsigned long long))

#define AL_FLOAT_TYPE(type)                                                                                                                                      \
    (AL_COMPILER_TYPES_COMPATIBLE(type, float) ||                                                                                                                \
    AL_COMPILER_TYPES_COMPATIBLE(type, double))

/* This macro evaluates to 1 when ((both types are integer types) || (both types are floating-point types)). */

#define AL_COMPATIBLE_SCALAR_TYPES(a, b)          \
    AL_COMPILER_IF(AL_INT_TYPE(a))                \
        AL_COMPILER_IF(AL_INT_TYPE(b))            \
            1                                     \
        AL_COMPILER_ELSE()                        \
            0                                     \
        AL_COMPILER_END_IF()                      \
    AL_COMPILER_ELSE()                            \
        AL_COMPILER_IF(AL_FLOAT_TYPE(a))          \
            AL_COMPILER_IF(AL_FLOAT_TYPE(b))      \
                1                                 \
            AL_COMPILER_ELSE()                    \
                0                                 \
            AL_COMPILER_END_IF()                  \
        AL_COMPILER_ELSE()                        \
            0                                     \
        AL_COMPILER_END_IF()                      \
    AL_COMPILER_END_IF()

#define AL_NO_OP (void)0