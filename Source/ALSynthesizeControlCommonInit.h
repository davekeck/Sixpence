/* This macro synthesizes the appropriate methods for an NSControl subclass to allow for a -commonInit method to be called when
   an instance is created. */

#define ALSynthesizeControlCommonInit(className)                                                               \
                                                                                                               \
    - (id)initWithFrame: (NSRect)newFrame                                                                      \
    {                                                                                                          \
                                                                                                               \
        if (!(self = [super initWithFrame: newFrame]))                                                         \
            return nil;                                                                                        \
                                                                                                               \
        /* Call the -commonInit method for the current class _only_ and return its result. */                  \
                                                                                                               \
        return [className instanceMethodForSelector: @selector(commonInit)](self, @selector(commonInit));      \
                                                                                                               \
    }                                                                                                          \
                                                                                                               \
    - (id)initWithCoder: (NSCoder *)coder                                                                      \
    {                                                                                                          \
                                                                                                               \
        if (!(self = [super initWithCoder: coder]))                                                            \
            return nil;                                                                                        \
                                                                                                               \
        /* Call the -commonInit method for the current class _only_ and return its result. */                  \
                                                                                                               \
        return [className instanceMethodForSelector: @selector(commonInit)](self, @selector(commonInit));      \
                                                                                                               \
    }
