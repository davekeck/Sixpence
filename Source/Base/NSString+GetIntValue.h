#import <Foundation/Foundation.h>

@interface NSString (GetIntValue)

- (BOOL)getSignedCharValue: (signed char *)outValue;
- (BOOL)getUnsignedCharValue: (unsigned char *)outValue;

- (BOOL)getSignedShortValue: (signed short *)outValue;
- (BOOL)getUnsignedShortValue: (unsigned short *)outValue;

- (BOOL)getSignedIntValue: (signed int *)outValue;
- (BOOL)getUnsignedIntValue: (unsigned int *)outValue;

- (BOOL)getSignedLongValue: (signed long *)outValue;
- (BOOL)getUnsignedLongValue: (unsigned long *)outValue;

- (BOOL)getSignedLongLongValue: (signed long long *)outValue;
- (BOOL)getUnsignedLongLongValue: (unsigned long long *)outValue;

- (BOOL)getIntegerValue: (NSInteger *)outValue;
- (BOOL)getUIntegerValue: (NSUInteger *)outValue;

- (BOOL)getInt8Value: (int8_t *)outValue;
- (BOOL)getUInt8Value: (uint8_t *)outValue;

- (BOOL)getInt16Value: (int16_t *)outValue;
- (BOOL)getUInt16Value: (uint16_t *)outValue;

- (BOOL)getInt32Value: (int32_t *)outValue;
- (BOOL)getUInt32Value: (uint32_t *)outValue;

- (BOOL)getInt64Value: (int64_t *)outValue;
- (BOOL)getUInt64Value: (uint64_t *)outValue;

@end