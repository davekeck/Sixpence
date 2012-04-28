#pragma once
#include "al_int_private.h"

/* 'Objects' can be either variables or types. */

#define AL_INT_VALID_VALUE_FOR_OBJECT(value, object)                     \
({                                                                       \
                                                                         \
        AL_COMPILER_ASSERT(AL_INT_TYPE(__typeof__(value)));              \
        AL_COMPILER_ASSERT(AL_INT_TYPE(__typeof__(object)));             \
                                                                         \
    AL_INT_PRIVATE_VALID_VALUE_FOR_TYPE(value, __typeof__(object));      \
                                                                         \
})

#define AL_INT_MIN_VALUE_FOR_OBJECT(object)                       \
({                                                                \
                                                                  \
        AL_COMPILER_ASSERT(AL_INT_TYPE(__typeof__(object)));      \
                                                                  \
    AL_INT_PRIVATE_MIN_VALUE_FOR_TYPE(__typeof__(object));        \
                                                                  \
})

#define AL_INT_MAX_VALUE_FOR_OBJECT(object)                       \
({                                                                \
                                                                  \
        AL_COMPILER_ASSERT(AL_INT_TYPE(__typeof__(object)));      \
                                                                  \
    AL_INT_PRIVATE_MAX_VALUE_FOR_TYPE(__typeof__(object));        \
                                                                  \
})

#define AL_INT_OBJECT_CAN_BE_NEGATIVE(object)                     \
({                                                                \
                                                                  \
        AL_COMPILER_ASSERT(AL_INT_TYPE(__typeof__(object)));      \
                                                                  \
    AL_INT_PRIVATE_TYPE_CAN_BE_NEGATIVE(__typeof__(object));      \
                                                                  \
})

#define AL_INT_GREATER_THAN(a, b)                                                                     \
({                                                                                                    \
                                                                                                      \
    __typeof__(a) AL_VAR(AL_INT_GREATER_THAN, x) = (a);                                               \
    __typeof__(b) AL_VAR(AL_INT_GREATER_THAN, y) = (b);                                               \
                                                                                                      \
        AL_COMPILER_ASSERT(AL_INT_TYPE(__typeof__(a)));                                               \
        AL_COMPILER_ASSERT(AL_INT_TYPE(__typeof__(b)));                                               \
                                                                                                      \
    AL_INT_PRIVATE_GREATER_THAN(AL_VAR(AL_INT_GREATER_THAN, x), AL_VAR(AL_INT_GREATER_THAN, y));      \
                                                                                                      \
})

#define AL_INT_GREATER_THAN_OR_EQUAL(a, b)                                                                                       \
({                                                                                                                               \
                                                                                                                                 \
    __typeof__(a) AL_VAR(AL_INT_GREATER_THAN_OR_EQUAL, x) = (a);                                                                 \
    __typeof__(b) AL_VAR(AL_INT_GREATER_THAN_OR_EQUAL, y) = (b);                                                                 \
                                                                                                                                 \
        AL_COMPILER_ASSERT(AL_INT_TYPE(__typeof__(a)));                                                                          \
        AL_COMPILER_ASSERT(AL_INT_TYPE(__typeof__(b)));                                                                          \
                                                                                                                                 \
    AL_INT_PRIVATE_GREATER_THAN_OR_EQUAL(AL_VAR(AL_INT_GREATER_THAN_OR_EQUAL, x), AL_VAR(AL_INT_GREATER_THAN_OR_EQUAL, y));      \
                                                                                                                                 \
})

#define AL_INT_LESS_THAN(a, b) AL_INT_GREATER_THAN(b, a)
#define AL_INT_LESS_THAN_OR_EQUAL(a, b) AL_INT_GREATER_THAN_OR_EQUAL(b, a)