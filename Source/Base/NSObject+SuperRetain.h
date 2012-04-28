/* This category is to ease supporting both RC and GC by always ensuring that the receiver is retained, released, or autoreleased. */

#import <Foundation/Foundation.h>

@interface NSObject (SuperRetain)

- (id)superRetain;
- (void)superRelease;
- (id)superAutorelease;

@end