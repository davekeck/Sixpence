/* This macro synthesizes the appropriate methods for an NSCell subclass to allow for a -commonInit method to be called when
   an instance is created. */

#define ALSynthesizeCellCommonInit(className)                                                                  \
                                                                                                               \
    - (id)initTextCell: (NSString *)string                                                                     \
    {                                                                                                          \
                                                                                                               \
        if (!(self = [super initTextCell: string]))                                                            \
            return nil;                                                                                        \
                                                                                                               \
        /* Call the -commonInit method for the current class _only_ and return its result. */                  \
                                                                                                               \
        return [className instanceMethodForSelector: @selector(commonInit)](self, @selector(commonInit));      \
                                                                                                               \
    }                                                                                                          \
                                                                                                               \
    - (id)initImageCell: (NSImage *)image                                                                      \
    {                                                                                                          \
                                                                                                               \
        if (!(self = [super initImageCell: image]))                                                            \
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
