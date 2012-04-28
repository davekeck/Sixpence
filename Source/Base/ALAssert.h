#define ALAssertOrRaise(condition) AL_ASSERT_OR_PERFORM((condition), [NSException raise: NSGenericException format: @"An exception occurred"])
#define ALAssertOrAbort AL_ASSERT_OR_ABORT
#define ALAssertOrPerform AL_ASSERT_OR_PERFORM