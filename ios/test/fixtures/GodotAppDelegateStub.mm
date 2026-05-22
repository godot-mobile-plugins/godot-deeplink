//
// © 2024-present https://github.com/cengiz-pz
//
// GodotAppDelegateStub.mm
//
// Provides a concrete ObjC class for GDTApplicationDelegate so the test
// bundle loads successfully.
//
// Background
// ----------
// deeplink_service.mm contains a C++ static initialiser:
//
//   struct DeeplinkServiceInitializer {
//       DeeplinkServiceInitializer() {
//           [GDTApplicationDelegate addService:[DeeplinkService shared]];
//       }
//   };
//   static DeeplinkServiceInitializer initializer;
//
// This runs at dlopen() time when the test bundle is loaded.  ObjC class
// references are resolved eagerly by the dynamic linker — before any code
// runs — so `-undefined dynamic_lookup` cannot defer them.  We must provide
// a real class with the right name.
//
// The stub's +addService: is a no-op: in the test environment there is no
// Godot app delegate to register with, and no test exercises that code path.
//

#import <Foundation/Foundation.h>

@interface GDTApplicationDelegate : NSObject
+ (void)addService:(id)service;
@end

@implementation GDTApplicationDelegate
+ (void)addService:(id)service { (void)service; }
@end
