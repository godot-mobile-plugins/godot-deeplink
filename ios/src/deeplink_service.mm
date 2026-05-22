//
// © 2024-present https://github.com/cengiz-pz
//

#import "deeplink_service.h"
#import "deeplink_logger.h"
#import "deeplink_plugin.h"
#import "gdp_converter.h"
#import "godot_app_delegate.h"

struct DeeplinkServiceInitializer {
	DeeplinkServiceInitializer() { [GDTApplicationDelegate addService:[DeeplinkService shared]]; }
};
static DeeplinkServiceInitializer initializer;

@interface DeeplinkService ()
- (void)processURL:(NSURL *)url fromSource:(NSString *)source;
@end

@implementation DeeplinkService

- (instancetype)init {
	self = [super init];
	return self;
}

+ (instancetype)shared {
	static DeeplinkService *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[DeeplinkService alloc] init];
	});
	return sharedInstance;
}

#pragma mark - Core URL Processing Helper

- (void)processURL:(NSURL *)url fromSource:(NSString *)source {
	if (!url) {
		os_log_debug(deeplink_log, "Deeplink plugin: URL is empty from source: %@", source);
		return;
	}

	DeeplinkPlugin::receivedUrl = [[DeeplinkUrl alloc] initWithNsUrl:url];

	BOOL isCustomScheme = ![url.scheme isEqualToString:@"http"] && ![url.scheme isEqualToString:@"https"];
	os_log_debug(deeplink_log, "Deeplink plugin: %@ received via [%@]: %@",
			isCustomScheme ? @"Custom scheme" : @"Universal Link", source, url.absoluteString);

	DeeplinkPlugin *plugin = DeeplinkPlugin::get_singleton();
	if (plugin) {
		// CHANGE THIS: Defer the signal until Godot's main loop has fully resumed
		plugin->call_deferred("emit_signal", DEEPLINK_RECEIVED_SIGNAL, [DeeplinkPlugin::receivedUrl buildRawData]);
	}
}

#pragma mark - UIApplicationDelegate Methods (Legacy / Non-Scene Lifecycle)

// Active / Background state via Custom Scheme
- (BOOL)application:(UIApplication *)app
			openURL:(NSURL *)url
			options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
	[self processURL:url fromSource:@"AppDelegate openURL"];
	return YES;
}

// Active / Background state via Universal Link
- (BOOL)application:(UIApplication *)app
		continueUserActivity:(NSUserActivity *)userActivity
		  restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler {
	if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
		[self processURL:userActivity.webpageURL fromSource:@"AppDelegate continueUserActivity"];
	}
	return YES;
}

// Cold Start (App completely terminated)
- (BOOL)application:(UIApplication *)app
		didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
	if (launchOptions) {
		NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
		if (url) {
			[self processURL:url fromSource:@"AppDelegate didFinishLaunching (URLKey)"];
		} else {
			NSDictionary *userActivityDict =
					[launchOptions objectForKey:UIApplicationLaunchOptionsUserActivityDictionaryKey];
			if (userActivityDict) {
				url = [userActivityDict objectForKey:UIApplicationLaunchOptionsURLKey];
				if (url) {
					[self processURL:url fromSource:@"AppDelegate didFinishLaunching (UserActivity URLKey)"];
				} else {
					NSUserActivity *userActivity =
							[userActivityDict objectForKey:@"UIApplicationLaunchOptionsUserActivityKey"];
					if (userActivity && [userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
						[self processURL:userActivity.webpageURL
								fromSource:@"AppDelegate didFinishLaunching (UserActivity Web)"];
					}
				}
			}
		}
	}
	return YES;
}

#pragma mark - UIWindowSceneDelegate Methods (Modern Scene Lifecycle)

// Scene Cold Start (App terminated, launched directly into a Scene)
- (void)scene:(UIScene *)scene
		willConnectToSession:(UISceneSession *)session
					 options:(UISceneConnectionOptions *)connectionOptions {
	// Handle Custom Scheme Cold Start via Scene
	if (connectionOptions.URLContexts.count > 0) {
		NSURL *url = connectionOptions.URLContexts.anyObject.URL; // Fixed: .url -> .URL
		[self processURL:url fromSource:@"SceneDelegate willConnectToSession (Custom Scheme)"];
	}

	// Handle Universal Link Cold Start via Scene
	if (connectionOptions.userActivities.count > 0) { // Fixed: extracted from userActivities set
		NSUserActivity *userActivity = connectionOptions.userActivities.anyObject;
		if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
			[self processURL:userActivity.webpageURL fromSource:@"SceneDelegate willConnectToSession (Universal Link)"];
		}
	}
}

// Scene Active / Background state via Custom Scheme
- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
	UIOpenURLContext *context = URLContexts.anyObject;
	if (context) {
		[self processURL:context.URL fromSource:@"SceneDelegate openURLContexts"]; // Fixed: .url -> .URL
	}
}

// Scene Active / Background state via Universal Link
- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
	if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
		[self processURL:userActivity.webpageURL fromSource:@"SceneDelegate continueUserActivity"];
	}
}

@end
