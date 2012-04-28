#import "ALPipe.h"

#import "al_modify_descriptor_flags.h"

#pragma mark -
#pragma mark Class Continuations
#pragma mark -

@interface ALPipe ()

- (void)cleanup;

@end

@implementation ALPipe

#pragma mark -
#pragma mark Creation
#pragma mark -

+ (void)sharedReadPipe: (ALPipe **)outReadPipe closeOnDealloc: (BOOL)closeReadPipeOnDealloc
    sharedWritePipe: (ALPipe **)outWritePipe closeOnDealloc: (BOOL)closeWritePipeOnDealloc
{

    ALPipe *readPipe = nil,
           *writePipe = nil;
    
    if (outReadPipe)
    {
    
        readPipe = [[(ALPipe *)[ALPipe alloc] initWithOptions: (ALPipe_Options_CloseReadDescriptorOnExec |
            (closeReadPipeOnDealloc ? (ALPipe_Options_CloseReadDescriptorOnDealloc | ALPipe_Options_CloseWriteDescriptorOnDealloc) : 0))] autorelease];
    
    }
    
    if (outWritePipe)
    {
    
        writePipe = [[(ALPipe *)[ALPipe alloc] initWithOptions: (ALPipe_Options_CloseWriteDescriptorOnExec |
            (closeWritePipeOnDealloc ? (ALPipe_Options_CloseReadDescriptorOnDealloc | ALPipe_Options_CloseWriteDescriptorOnDealloc) : 0))] autorelease];
    
    }
    
    if (outReadPipe)
        *outReadPipe = readPipe;
    
    if (outWritePipe)
        *outWritePipe = writePipe;

}

+ (void)prepareSharedReadPipeAfterExec: (ALPipe *)readPipe sharedWritePipe: (ALPipe *)writePipe
{

    [readPipe closeWriteDescriptor];
    [writePipe closeReadDescriptor];

}

+ (void)closeSharedReadPipe: (ALPipe *)readPipe sharedWritePipe: (ALPipe *)writePipe
{

    [readPipe closeDescriptors];
    [writePipe closeDescriptors];

}

- (id)initWithOptions: (ALPipe_Options)newOptions
{

    int tempPipe[2],
        pipeResult = 0;
    
    if (!(self = [super init]))
        return nil;
    
    options = newOptions;
    pipeResult = pipe(tempPipe);
    
        ALAssertOrRaise(!pipeResult);
    
    readDescriptor = al_descriptor_create(YES, tempPipe[0]);
    writeDescriptor = al_descriptor_create(YES, tempPipe[1]);
    
    if (options & ALPipe_Options_CloseReadDescriptorOnExec)
    {
    
        BOOL setCloseOnExecResult = NO;
        
        setCloseOnExecResult = al_mdf_set_descriptor_close_on_exec(readDescriptor.descriptor, YES);
        
            ALAssertOrRaise(setCloseOnExecResult);
    
    }
    
    if (options & ALPipe_Options_CloseWriteDescriptorOnExec)
    {
    
        BOOL setCloseOnExecResult = NO;
        
        setCloseOnExecResult = al_mdf_set_descriptor_close_on_exec(writeDescriptor.descriptor, YES);
        
            ALAssertOrRaise(setCloseOnExecResult);
    
    }
    
    return self;

}

- (void)dealloc
{

    [self cleanup];
    [super dealloc];

}

- (void)finalize
{

    [self cleanup];
    [super finalize];

}

- (void)cleanup
{

    if (options & ALPipe_Options_CloseReadDescriptorOnDealloc)
        [self closeReadDescriptor];
    
    if (options & ALPipe_Options_CloseWriteDescriptorOnDealloc)
        [self closeWriteDescriptor];

}

#pragma mark -
#pragma mark Properties
#pragma mark -

@synthesize readDescriptor;
@synthesize writeDescriptor;

- (al_descriptor_t)readDescriptor
{

    @synchronized(self)
    {
    
        return readDescriptor;
    
    }

}

- (al_descriptor_t)writeDescriptor
{

    @synchronized(self)
    {
    
        return writeDescriptor;
    
    }

}

#pragma mark -
#pragma mark Methods
#pragma mark -

- (void)closeReadDescriptor
{

    @synchronized(self)
    {
    
        al_descriptor_cleanup(&readDescriptor, [NSException raise: NSGenericException format: @"Failed to cleanup descriptor"]);
    
    }

}

- (void)closeWriteDescriptor
{

    @synchronized(self)
    {
    
        al_descriptor_cleanup(&writeDescriptor, [NSException raise: NSGenericException format: @"Failed to cleanup descriptor"]);
    
    }

}

- (void)closeDescriptors
{

    [self closeReadDescriptor];
    [self closeWriteDescriptor];

}

@end