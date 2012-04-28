#import <Foundation/Foundation.h>

#import "al_hash.h"

/* Category Interfaces */

@interface NSData (Hash)

/* Methods */

- (NSData *)hashWithType: (al_hash_hash_type)hashType;
- (NSString *)stringHashWithType: (al_hash_hash_type)hashType;

@end

@interface NSString (Hash)

/* Methods */

- (NSData *)hashWithType: (al_hash_hash_type)hashType;
- (NSString *)stringHashWithType: (al_hash_hash_type)hashType;

@end