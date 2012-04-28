/* This class is thread safe. */

#import <Foundation/Foundation.h>

enum
{

    ALPipe_Options_Init,
    
    ALPipe_Options_CloseReadDescriptorOnExec = (1 << 0),
    ALPipe_Options_CloseWriteDescriptorOnExec = (1 << 1),
    
    ALPipe_Options_CloseReadDescriptorOnDealloc = (1 << 2),
    ALPipe_Options_CloseWriteDescriptorOnDealloc = (1 << 3),

}; typedef int ALPipe_Options;

@interface ALPipe : NSObject
{

@private
    
    ALPipe_Options options;
    al_descriptor_t readDescriptor;
    al_descriptor_t writeDescriptor;

}

/* Creation */

+ (void)sharedReadPipe: (ALPipe **)outReadPipe closeOnDealloc: (BOOL)closeReadPipeOnDealloc
    sharedWritePipe: (ALPipe **)outWritePipe closeOnDealloc: (BOOL)closeWritePipeOnDealloc;

+ (void)prepareSharedReadPipeAfterExec: (ALPipe *)readPipe sharedWritePipe: (ALPipe *)writePipe;

+ (void)closeSharedReadPipe: (ALPipe *)readPipe sharedWritePipe: (ALPipe *)writePipe;

- (id)initWithOptions: (ALPipe_Options)newOptions;

/* Properties */

@property(readonly) al_descriptor_t readDescriptor;
@property(readonly) al_descriptor_t writeDescriptor;

/* Methods */

- (void)closeReadDescriptor;
- (void)closeWriteDescriptor;
- (void)closeDescriptors;

@end