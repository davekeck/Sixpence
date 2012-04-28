#import <Foundation/Foundation.h>

/* Type Definitions */

enum
{

    ALCommandInterface_Options_EmptyEnvironment = (1 << 0),
    ALCommandInterface_Options_ExecuteAsRoot = (1 << 1),
    ALCommandInterface_Options_NullStandardDescriptors = (1 << 2),
    ALCommandInterface_Options_CaptureStdout = (1 << 3),
    ALCommandInterface_Options_ConsiderProcessStatus = (1 << 4),

}; typedef int ALCommandInterface_Options;

/* Class Interfaces */

@interface ALCommandInterface : ALSingleton

/* Methods */

- (BOOL)performCommandWithOptions: (ALCommandInterface_Options)options stdoutData: (NSData **)outStdoutData
    pathAndArguments: (NSString *)firstArgument, ... NS_REQUIRES_NIL_TERMINATION;

@end