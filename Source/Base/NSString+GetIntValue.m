#import "NSString+GetIntValue.h"

#pragma mark Function Interfaces
#pragma mark -

static BOOL NSString_GetIntValue_GetIntValueFromString(const char *string, BOOL signedValue, size_t valueSize, void *outValue);

#pragma mark -
#pragma mark Category Implementations
#pragma mark -

@implementation NSString (GetIntValue)

#pragma mark -
#pragma mark Methods
#pragma mark -

- (BOOL)getSignedCharValue: (signed char *)outValue
{

    return [self getInt8Value: outValue];

}

- (BOOL)getUnsignedCharValue: (unsigned char *)outValue
{

    return [self getUInt8Value: outValue];

}

- (BOOL)getSignedShortValue: (signed short *)outValue
{

    return [self getInt16Value: outValue];

}

- (BOOL)getUnsignedShortValue: (unsigned short *)outValue
{

    return [self getUInt16Value: outValue];

}

- (BOOL)getSignedIntValue: (signed int *)outValue
{

    return [self getInt32Value: outValue];

}

- (BOOL)getUnsignedIntValue: (unsigned int *)outValue
{

    return [self getUInt32Value: outValue];

}

- (BOOL)getSignedLongValue: (signed long *)outValue
{

    #ifdef __LP64__
    
        return [self getInt64Value: (int64_t *)outValue];
    
    #else
    
        return [self getInt32Value: (int32_t *)outValue];
    
    #endif

}

- (BOOL)getUnsignedLongValue: (unsigned long *)outValue
{

    #ifdef __LP64__
    
        return [self getUInt64Value: (uint64_t *)outValue];
    
    #else
    
        return [self getUInt32Value: (uint32_t *)outValue];
    
    #endif

}

- (BOOL)getSignedLongLongValue: (signed long long *)outValue
{

    return [self getInt64Value: outValue];

}

- (BOOL)getUnsignedLongLongValue: (unsigned long long *)outValue
{

    return [self getUInt64Value: outValue];

}

- (BOOL)getIntegerValue: (NSInteger *)outValue
{

    #ifdef __LP64__
    
        return [self getInt64Value: (int64_t *)outValue];
    
    #else
    
        return [self getInt32Value: (int32_t *)outValue];
    
    #endif

}

- (BOOL)getUIntegerValue: (NSUInteger *)outValue
{

    #ifdef __LP64__
    
        return [self getUInt64Value: (uint64_t *)outValue];
    
    #else
    
        return [self getUInt32Value: (uint32_t *)outValue];
    
    #endif

}

- (BOOL)getInt8Value: (int8_t *)outValue
{

    return NSString_GetIntValue_GetIntValueFromString([self UTF8String], YES, sizeof(*outValue), outValue);

}

- (BOOL)getUInt8Value: (uint8_t *)outValue
{

    return NSString_GetIntValue_GetIntValueFromString([self UTF8String], NO, sizeof(*outValue), outValue);

}

- (BOOL)getInt16Value: (int16_t *)outValue
{

    return NSString_GetIntValue_GetIntValueFromString([self UTF8String], YES, sizeof(*outValue), outValue);

}

- (BOOL)getUInt16Value: (uint16_t *)outValue
{

    return NSString_GetIntValue_GetIntValueFromString([self UTF8String], NO, sizeof(*outValue), outValue);

}

- (BOOL)getInt32Value: (int32_t *)outValue
{

    return NSString_GetIntValue_GetIntValueFromString([self UTF8String], YES, sizeof(*outValue), outValue);

}

- (BOOL)getUInt32Value: (uint32_t *)outValue
{

    return NSString_GetIntValue_GetIntValueFromString([self UTF8String], NO, sizeof(*outValue), outValue);

}

- (BOOL)getInt64Value: (int64_t *)outValue
{

    return NSString_GetIntValue_GetIntValueFromString([self UTF8String], YES, sizeof(*outValue), outValue);

}

- (BOOL)getUInt64Value: (uint64_t *)outValue
{

    return NSString_GetIntValue_GetIntValueFromString([self UTF8String], NO, sizeof(*outValue), outValue);

}

@end

#pragma mark -
#pragma mark Function Implementations
#pragma mark -

static BOOL NSString_GetIntValue_GetIntValueFromString(const char *string, BOOL signedValue, size_t valueSize, void *outValue)
{

    #define NSString_GetIntValue_GetIntValueFromString_AssignOutValue(valueSize)                                    \
                                                                                                                    \
    do                                                                                                              \
    {                                                                                                               \
                                                                                                                    \
        if (signedValue)                                                                                            \
        {                                                                                                           \
                                                                                                                    \
            if (negative && absoluteValue)                                                                          \
                *(int##valueSize##_t *)outValue = (int##valueSize##_t)((-((int64_t)(absoluteValue - 1))) - 1);      \
                                                                                                                    \
            else                                                                                                    \
                *(int##valueSize##_t *)outValue = (int##valueSize##_t)absoluteValue;                                \
                                                                                                                    \
        }                                                                                                           \
                                                                                                                    \
        else                                                                                                        \
            *(uint##valueSize##_t *)outValue = (uint##valueSize##_t)absoluteValue;                                  \
                                                                                                                    \
    } while (NO)
    
    uint64_t maximumValue = 0,
             cutoffValue = 0,
             cutoffValueRemainder = 0,
             absoluteValue = 0;
    BOOL negative = NO,
         foundDigit = NO;
    
        NSCParameterAssert(string);
        NSCParameterAssert(valueSize == sizeof(uint8_t) || valueSize == sizeof(uint16_t) ||
            valueSize == sizeof(uint32_t) || valueSize == sizeof(uint64_t));
        NSCParameterAssert(outValue);
    
    if (*string == '-')
    {
    
        negative = YES;
        string++;
    
    }
    
    maximumValue = (((((uint64_t)1 << ((valueSize * 8) - 1)) - 1) * (signedValue ? 1 : 2)) + ((negative || !signedValue) ? 1 : 0));
    cutoffValue = (maximumValue / 10);
    cutoffValueRemainder = (maximumValue % 10);
    
    for (;; string++)
    {
    
            ALConfirmOrPerform(ALValueInRange(*string, '0', '9') || (!*string && foundDigit), return NO);
        
        if (isdigit(*string))
        {
        
            uint8_t currentDigit = 0;
            
            currentDigit = digittoint(*string);
            
                /* First, confirm that if currentDigit > 0 and the supplied string represents a negative value, then the caller must be prepared to accept a
                   signed value. (This check allows us to accept negative zero strings, ie '-0', when the caller only accepts unsigned values.)
                   
                   Second, we'll check for overflow conditions by comparing absoluteValue with our cutoffValue, and our currentDigit with our
                   cutoffValueRemainder. */
                
                ALConfirmOrPerform(!(currentDigit && negative && !signedValue), return NO);
                ALConfirmOrPerform((absoluteValue < cutoffValue) || ((absoluteValue == cutoffValue) && (currentDigit <= cutoffValueRemainder)), return NO);
            
            absoluteValue = ((absoluteValue * 10) + currentDigit);
            foundDigit = YES;
        
        }
        
        else if (!*string && foundDigit)
            break;
    
    }
    
    /* We need to perform some arithmetic tricks when the value is negative. This is because (according to C99) casting from an unsigned value to a
       signed value results in undefined behavior if the unsigned value cannot be represented in the new signed type. That is, the result of
       '(char)value = (unsigned char)128' is undefined.
       
       To work around this, we simply subtract one from the unsigned type (128 - 1), which guarantees that the unsigned value can be represented in
       the signed type. We then cast the unsigned value to the signed type ((signed char)127), and then make the value negative (-((signed char)127)).
       Finally, we subtract one from the new signed type (-127 - 1 == -128), to balance the original subtraction. This results in a C99-compatible way
       of making an unsigned integer negative, when it's known that the negative equivalent of the unsigned integer can be represented in the signed
       type. */
    
    if (valueSize == sizeof(uint8_t))
        NSString_GetIntValue_GetIntValueFromString_AssignOutValue(8);
    
    else if (valueSize == sizeof(uint16_t))
        NSString_GetIntValue_GetIntValueFromString_AssignOutValue(16);
    
    else if (valueSize == sizeof(uint32_t))
        NSString_GetIntValue_GetIntValueFromString_AssignOutValue(32);
    
    else if (valueSize == sizeof(uint64_t))
        NSString_GetIntValue_GetIntValueFromString_AssignOutValue(64);
    
    return YES;
    #undef NSString_GetIntValue_GetIntValueFromString_AssignOutValue

}