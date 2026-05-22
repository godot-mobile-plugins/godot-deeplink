//
// © 2024-present https://github.com/cengiz-pz
//

#ifndef deeplink_plugin_application_delegate_h
#define deeplink_plugin_application_delegate_h

#import <UIKit/UIKit.h>

@interface DeeplinkService : UIResponder <UIApplicationDelegate, UIWindowSceneDelegate>

+ (instancetype)shared;

// UIApplicationDelegate Methods
- (BOOL)application:(UIApplication *)app
			openURL:(NSURL *)url
			options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options;

- (BOOL)application:(UIApplication *)app
		continueUserActivity:(NSUserActivity *)userActivity
		  restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler;

- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary<NSString *, id> *)launchOptions;

// UIWindowSceneDelegate Methods (Handles iOS 13+ Scene Lifecycle)
- (void)scene:(UIScene *)scene
		willConnectToSession:(UISceneSession *)session
					 options:(UISceneConnectionOptions *)connectionOptions;
- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts;
- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity;

@end

#endif /* deeplink_plugin_application_delegate_h */
