//
// © 2024-present https://github.com/cengiz-pz
//

#import "DeeplinkTestFakes.h"

// ---------------------------------------------------------------------------
// FakeURLContext
// ---------------------------------------------------------------------------

@implementation FakeURLContext

- (instancetype)initWithURL:(NSURL *)url {
    if ((self = [super init])) {
        _URL = url;
    }
    return self;
}

// Satisfy the compiler: make a safe no-arg path rather than leaving it
// ambiguous.  Tests always use -initWithURL:.
- (instancetype)init {
    return [self initWithURL:nil];
}

@end


// ---------------------------------------------------------------------------
// FakeConnectionOptions
// ---------------------------------------------------------------------------

@implementation FakeConnectionOptions

- (instancetype)initWithURLContexts:(NSSet *)ctxSet
                     userActivities:(NSSet *)activities {
    if ((self = [super init])) {
        _URLContexts    = ctxSet    ?: [NSSet set];
        _userActivities = activities ?: [NSSet set];
    }
    return self;
}

- (instancetype)init {
    return [self initWithURLContexts:[NSSet set] userActivities:[NSSet set]];
}

+ (instancetype)optionsWithURLContexts:(NSSet *)ctxSet
                        userActivities:(NSSet *)activities {
    return [[self alloc] initWithURLContexts:ctxSet userActivities:activities];
}

@end
