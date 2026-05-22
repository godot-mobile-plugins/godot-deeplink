//
// © 2024-present https://github.com/cengiz-pz
//
// DeeplinkTestFakes.h
//
// Lightweight test doubles for UIKit types that cannot be instantiated or
// subclassed in a unit-test target.
//
// Design rule: each fake is a plain NSObject that exposes only the
// properties DeeplinkService actually reads.  Every call-site casts to
// (id) so the ObjC runtime dispatches to our implementation rather than
// the real UIKit class.  No UIKit superclass, no unavailable-init fights,
// no ivar-synthesis battles.
//

#ifndef DeeplinkTestFakes_h
#define DeeplinkTestFakes_h

#import <Foundation/Foundation.h>

// ---------------------------------------------------------------------------
// FakeURLContext
//
// Replaces UIOpenURLContext in tests.
//
// DeeplinkService reads exactly one property from a UIOpenURLContext:
//
//   context.URL   (declared `readonly copy` on UIOpenURLContext)
//
// We expose it as `readwrite strong` on a plain NSObject.  Cast to (id)
// before passing to any method typed UIOpenURLContext* — ObjC message
// dispatch is name-based, so the runtime finds -URL on our object just
// as it would on the real one.
// ---------------------------------------------------------------------------

@interface FakeURLContext : NSObject

@property (nonatomic, strong, readwrite) NSURL *URL;

- (instancetype)initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;

@end


// ---------------------------------------------------------------------------
// FakeConnectionOptions
//
// Replaces UISceneConnectionOptions in tests.
//
// DeeplinkService reads exactly two properties from UISceneConnectionOptions:
//
//   options.URLContexts      → NSSet<UIOpenURLContext *>
//   options.userActivities   → NSSet<NSUserActivity *>
//
// Cast to (UISceneConnectionOptions *) before passing to any method typed
// with that parameter — ObjC dispatch will still find our implementations.
// ---------------------------------------------------------------------------

@interface FakeConnectionOptions : NSObject

@property (nonatomic, strong, readonly) NSSet *URLContexts;
@property (nonatomic, strong, readonly) NSSet *userActivities;

+ (instancetype)optionsWithURLContexts:(NSSet *)ctxSet
                        userActivities:(NSSet *)activities;

- (instancetype)initWithURLContexts:(NSSet *)ctxSet
                     userActivities:(NSSet *)activities NS_DESIGNATED_INITIALIZER;

@end

#endif /* DeeplinkTestFakes_h */
