//
// © 2024-present https://github.com/cengiz-pz
//

#import <XCTest/XCTest.h>

#import "deeplink_service.h"
#import "deeplink_plugin.h"
#import "deeplink_url.h"
#import "DeeplinkTestFixtures.h"
#import "DeeplinkTestFakes.h"

// ---------------------------------------------------------------------------
// DeeplinkServiceTests
//
// DeeplinkService is the Objective-C UIApplicationDelegate /
// UIWindowSceneDelegate that receives raw OS callbacks and forwards processed
// DeeplinkUrl values to the C++ plugin singleton.
//
// Testing strategy
// ----------------
//  1. Inject URLs via every public delegate entry-point.
//  2. Assert that DeeplinkPlugin::receivedUrl is populated correctly — this
//     is the observable side-effect that drives the Godot signal.
//
// No external mocking library is used.  UIOpenURLContext and
// UISceneConnectionOptions — both non-instantiable in unit-test targets —
// are replaced by FakeURLContext and FakeConnectionOptions declared in
// DeeplinkTestFakes.h.  The cast `(id)` at each call-site is intentional:
// we are passing a compatible duck-typed object to a method that reads a
// known subset of properties; ARC ownership is unaffected.
//
// Simulator / device note: UIApplication and UIScene are not instantiable
// in unit-test targets.  We pass nil wherever those objects are required;
// the implementation under test only reads from the options/activity
// arguments, so nil app/scene values are safe.
// ---------------------------------------------------------------------------

@interface DeeplinkServiceTests : XCTestCase {
    DeeplinkService *_service;
}
@end

@implementation DeeplinkServiceTests

- (void)setUp {
    [super setUp];
    _service = [DeeplinkService shared];
    DeeplinkPlugin::receivedUrl = nil;
}

- (void)tearDown {
    DeeplinkPlugin::receivedUrl = nil;
    [super tearDown];
}

// -- Helpers ------------------------------------------------------------------

- (NSDictionary *)launchOptionsWithURL:(NSURL *)url {
    return @{UIApplicationLaunchOptionsURLKey: url};
}

- (NSDictionary *)launchOptionsWithUniversalLinkActivity:(NSUserActivity *)activity {
    return @{
        UIApplicationLaunchOptionsUserActivityDictionaryKey: @{
            @"UIApplicationLaunchOptionsUserActivityKey": activity
        }
    };
}

/// Returns an NSSet<UIOpenURLContext *> containing one FakeURLContext for url.
- (NSSet<UIOpenURLContext *> *)urlContextsWithURL:(NSURL *)url
    API_AVAILABLE(ios(13.0)) {
    FakeURLContext *ctx = [[FakeURLContext alloc] initWithURL:url];
    return [NSSet setWithObject:(UIOpenURLContext *)ctx];
}

/// Returns a FakeConnectionOptions carrying a single custom-scheme URL context.
- (FakeConnectionOptions *)connectionOptionsWithCustomSchemeURL:(NSURL *)url
    API_AVAILABLE(ios(13.0)) {
    NSSet *ctxSet = [self urlContextsWithURL:url];
    return [FakeConnectionOptions optionsWithURLContexts:ctxSet
                                         userActivities:[NSSet set]];
}

/// Returns a FakeConnectionOptions carrying a Universal Link user-activity.
- (FakeConnectionOptions *)connectionOptionsWithActivity:(NSUserActivity *)activity
    API_AVAILABLE(ios(13.0)) {
    return [FakeConnectionOptions optionsWithURLContexts:[NSSet set]
                                         userActivities:[NSSet setWithObject:activity]];
}

/// Returns a FakeConnectionOptions with no contexts and no activities.
- (FakeConnectionOptions *)emptyConnectionOptions API_AVAILABLE(ios(13.0)) {
    return [FakeConnectionOptions optionsWithURLContexts:[NSSet set]
                                         userActivities:[NSSet set]];
}

// -- AppDelegate: openURL (active/background, custom scheme) ------------------

- (void)test_openURL_setsReceivedUrlScheme {
    [_service application:nil openURL:[DeeplinkTestFixtures customSchemeURL] options:@{}];
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.scheme, @"myapp");
}

- (void)test_openURL_setsReceivedUrlHost {
    [_service application:nil openURL:[DeeplinkTestFixtures customSchemeURL] options:@{}];
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.host, @"open");
}

- (void)test_openURL_setsReceivedUrlPath {
    [_service application:nil openURL:[DeeplinkTestFixtures customSchemeURL] options:@{}];
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.path, @"/product/42");
}

- (void)test_openURL_setsReceivedUrlQuery {
    [_service application:nil openURL:[DeeplinkTestFixtures customSchemeURL] options:@{}];
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.query, @"ref=banner&utm_source=email");
}

- (void)test_openURL_universalLinkScheme_setsSchemeHttps {
    [_service application:nil openURL:[DeeplinkTestFixtures universalLinkURL] options:@{}];
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.scheme, @"https");
}

- (void)test_openURL_returnsYES {
    BOOL result = [_service application:nil
                                openURL:[DeeplinkTestFixtures customSchemeURL]
                                options:@{}];
    XCTAssertTrue(result);
}

// -- AppDelegate: continueUserActivity (active/background, Universal Link) ----

- (void)test_continueUserActivity_browsingWeb_setsReceivedUrl {
    [_service application:nil
     continueUserActivity:[DeeplinkTestFixtures browsingWebActivity]
       restorationHandler:^(NSArray *_) {}];

    XCTAssertNotNil(DeeplinkPlugin::receivedUrl);
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.scheme, @"https");
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.host, @"example.com");
}

- (void)test_continueUserActivity_nonBrowsingType_doesNotSetReceivedUrl {
    [_service application:nil
     continueUserActivity:[DeeplinkTestFixtures nonBrowsingActivity]
       restorationHandler:^(NSArray *_) {}];

    XCTAssertNil(DeeplinkPlugin::receivedUrl,
                 @"Non-browsing activities must not populate receivedUrl");
}

- (void)test_continueUserActivity_returnsYES {
    BOOL result = [_service application:nil
                   continueUserActivity:[DeeplinkTestFixtures browsingWebActivity]
                     restorationHandler:^(NSArray *_) {}];
    XCTAssertTrue(result);
}

// -- AppDelegate: didFinishLaunchingWithOptions (cold start, custom scheme) ---

- (void)test_didFinishLaunching_withURLKey_setsReceivedUrlScheme {
    NSDictionary *opts = [self launchOptionsWithURL:[DeeplinkTestFixtures customSchemeURL]];
    [_service application:nil didFinishLaunchingWithOptions:opts];
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.scheme, @"myapp");
}

- (void)test_didFinishLaunching_withURLKey_setsReceivedUrlPath {
    NSDictionary *opts = [self launchOptionsWithURL:[DeeplinkTestFixtures customSchemeURL]];
    [_service application:nil didFinishLaunchingWithOptions:opts];
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.path, @"/product/42");
}

- (void)test_didFinishLaunching_withUniversalLinkActivity_setsReceivedUrl {
    NSUserActivity *activity = [DeeplinkTestFixtures browsingWebActivity];
    NSDictionary *opts = [self launchOptionsWithUniversalLinkActivity:activity];
    [_service application:nil didFinishLaunchingWithOptions:opts];

    XCTAssertNotNil(DeeplinkPlugin::receivedUrl);
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.scheme, @"https");
}

- (void)test_didFinishLaunching_withNilOptions_doesNotSetReceivedUrl {
    [_service application:nil didFinishLaunchingWithOptions:nil];
    XCTAssertNil(DeeplinkPlugin::receivedUrl);
}

- (void)test_didFinishLaunching_withEmptyOptions_doesNotSetReceivedUrl {
    [_service application:nil didFinishLaunchingWithOptions:@{}];
    XCTAssertNil(DeeplinkPlugin::receivedUrl);
}

- (void)test_didFinishLaunching_returnsYES {
    NSDictionary *opts = [self launchOptionsWithURL:[DeeplinkTestFixtures customSchemeURL]];
    BOOL result = [_service application:nil didFinishLaunchingWithOptions:opts];
    XCTAssertTrue(result);
}

// -- SceneDelegate: willConnectToSession (cold start, custom scheme) ----------

- (void)test_sceneWillConnect_customSchemeURL_setsReceivedUrlScheme API_AVAILABLE(ios(13.0)) {
    FakeConnectionOptions *opts =
        [self connectionOptionsWithCustomSchemeURL:[DeeplinkTestFixtures customSchemeURL]];

    [_service scene:nil willConnectToSession:nil options:(UISceneConnectionOptions *)opts];

    XCTAssertNotNil(DeeplinkPlugin::receivedUrl);
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.scheme, @"myapp");
}

- (void)test_sceneWillConnect_customSchemeURL_setsReceivedUrlPath API_AVAILABLE(ios(13.0)) {
    FakeConnectionOptions *opts =
        [self connectionOptionsWithCustomSchemeURL:[DeeplinkTestFixtures customSchemeURL]];

    [_service scene:nil willConnectToSession:nil options:(UISceneConnectionOptions *)opts];

    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.path, @"/product/42");
}

- (void)test_sceneWillConnect_universalLink_setsReceivedUrlHost API_AVAILABLE(ios(13.0)) {
    FakeConnectionOptions *opts =
        [self connectionOptionsWithActivity:[DeeplinkTestFixtures browsingWebActivity]];

    [_service scene:nil willConnectToSession:nil options:(UISceneConnectionOptions *)opts];

    XCTAssertNotNil(DeeplinkPlugin::receivedUrl);
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.host, @"example.com");
}

- (void)test_sceneWillConnect_nonBrowsingActivity_doesNotSetReceivedUrl API_AVAILABLE(ios(13.0)) {
    FakeConnectionOptions *opts =
        [self connectionOptionsWithActivity:[DeeplinkTestFixtures nonBrowsingActivity]];

    [_service scene:nil willConnectToSession:nil options:(UISceneConnectionOptions *)opts];

    XCTAssertNil(DeeplinkPlugin::receivedUrl);
}

- (void)test_sceneWillConnect_emptyOptions_doesNotSetReceivedUrl API_AVAILABLE(ios(13.0)) {
    [_service scene:nil
    willConnectToSession:nil
                options:(UISceneConnectionOptions *)[self emptyConnectionOptions]];

    XCTAssertNil(DeeplinkPlugin::receivedUrl);
}

// -- SceneDelegate: openURLContexts (active/background, custom scheme) --------

- (void)test_sceneOpenURLContexts_setsReceivedUrlScheme API_AVAILABLE(ios(13.0)) {
    NSSet *ctxSet = [self urlContextsWithURL:[DeeplinkTestFixtures customSchemeURL]];
    [_service scene:nil openURLContexts:ctxSet];
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.scheme, @"myapp");
}

- (void)test_sceneOpenURLContexts_setsReceivedUrlQuery API_AVAILABLE(ios(13.0)) {
    NSSet *ctxSet = [self urlContextsWithURL:[DeeplinkTestFixtures customSchemeURL]];
    [_service scene:nil openURLContexts:ctxSet];
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.query, @"ref=banner&utm_source=email");
}

- (void)test_sceneOpenURLContexts_emptySet_doesNotSetReceivedUrl API_AVAILABLE(ios(13.0)) {
    [_service scene:nil openURLContexts:[NSSet set]];
    XCTAssertNil(DeeplinkPlugin::receivedUrl);
}

- (void)test_sceneOpenURLContexts_universalLink_setsSchemeHttps API_AVAILABLE(ios(13.0)) {
    NSSet *ctxSet = [self urlContextsWithURL:[DeeplinkTestFixtures universalLinkURL]];
    [_service scene:nil openURLContexts:ctxSet];
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.scheme, @"https");
}

// -- SceneDelegate: continueUserActivity (active/background, Universal Link) --

- (void)test_sceneContinueActivity_browsingWeb_setsReceivedUrl API_AVAILABLE(ios(13.0)) {
    [_service scene:nil continueUserActivity:[DeeplinkTestFixtures browsingWebActivity]];
    XCTAssertNotNil(DeeplinkPlugin::receivedUrl);
    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.host, @"example.com");
}

- (void)test_sceneContinueActivity_nonBrowsing_doesNotSetReceivedUrl API_AVAILABLE(ios(13.0)) {
    [_service scene:nil continueUserActivity:[DeeplinkTestFixtures nonBrowsingActivity]];
    XCTAssertNil(DeeplinkPlugin::receivedUrl);
}

// -- processURL – nil guard ----------------------------------------------------

- (void)test_openURL_nilURL_doesNotSetReceivedUrl {
    [_service application:nil openURL:nil options:@{}];
    XCTAssertNil(DeeplinkPlugin::receivedUrl,
                 @"A nil URL must not overwrite receivedUrl");
}

// -- URL replacement across consecutive calls ----------------------------------

- (void)test_consecutiveCalls_latestURLWins {
    [_service application:nil openURL:[DeeplinkTestFixtures customSchemeURL] options:@{}];
    [_service application:nil openURL:[DeeplinkTestFixtures universalLinkURL] options:@{}];

    XCTAssertEqualObjects(DeeplinkPlugin::receivedUrl.scheme, @"https",
                          @"The second openURL call must overwrite the first");
}

@end
