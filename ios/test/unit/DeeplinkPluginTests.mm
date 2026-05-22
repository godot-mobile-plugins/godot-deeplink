//
// © 2024-present https://github.com/cengiz-pz
//

#import <XCTest/XCTest.h>

#import "deeplink_plugin.h"
#import "deeplink_url.h"
#import "DeeplinkTestFixtures.h"

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
static NSString *godotStringToNSString(const String &s) {
    return [NSString stringWithUTF8String:s.utf8().get_data()];
}

// ---------------------------------------------------------------------------
// DeeplinkPluginTests
//
// Strategy
// --------
// DeeplinkPlugin is a Godot singleton that interacts with a live engine.
// Rather than spin up the full Godot runtime, we exercise it through its
// public C++ API and the one shared static it exposes:
//
//   DeeplinkPlugin::receivedUrl   – set this to inject a URL under test
//
// Signal emission (emit_signal / call_deferred) is not exercised here;
// that integration path is covered by DeeplinkServiceTests which uses
// OCMock to verify the plugin receives the deferred call.
// ---------------------------------------------------------------------------

@interface DeeplinkPluginTests : XCTestCase {
    DeeplinkPlugin *_plugin;
}
@end

@implementation DeeplinkPluginTests

- (void)setUp {
    [super setUp];
    _plugin = new DeeplinkPlugin();
    // Start each test with no pending URL
    DeeplinkPlugin::receivedUrl = nil;
}

- (void)tearDown {
    DeeplinkPlugin::receivedUrl = nil;
    delete _plugin;
    _plugin = nullptr;
    [super tearDown];
}

// -- get_singleton -------------------------------------------------------------

- (void)test_getSingleton_afterConstruction_returnsNonNull {
    XCTAssertNotEqual(DeeplinkPlugin::get_singleton(), nullptr);
}

- (void)test_getSingleton_returnsSameInstance {
    XCTAssertEqual(DeeplinkPlugin::get_singleton(), _plugin);
}

// -- get_url ------------------------------------------------------------------

- (void)test_getUrl_whenReceivedUrlIsNil_returnsEmptyString {
    String result = _plugin->get_url();
    XCTAssertTrue(result.is_empty());
}

- (void)test_getUrl_whenReceivedUrlIsSet_returnsAbsoluteString {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];

    NSString *result = godotStringToNSString(_plugin->get_url());
    XCTAssertEqualObjects(result, DeeplinkTestFixtures.customSchemeAbsoluteString);
}

- (void)test_getUrl_universalLink_returnsAbsoluteString {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures universalLinkURL]];

    NSString *result = godotStringToNSString(_plugin->get_url());
    XCTAssertEqualObjects(result, @"https://example.com/shop/item?id=99#reviews");
}

// -- get_scheme ---------------------------------------------------------------

- (void)test_getScheme_whenNil_returnsEmptyString {
    XCTAssertTrue(_plugin->get_scheme().is_empty());
}

- (void)test_getScheme_customScheme_returnsCorrectScheme {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];

    XCTAssertEqualObjects(godotStringToNSString(_plugin->get_scheme()), @"myapp");
}

- (void)test_getScheme_universalLink_returnsHttps {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures universalLinkURL]];

    XCTAssertEqualObjects(godotStringToNSString(_plugin->get_scheme()), @"https");
}

// -- get_host -----------------------------------------------------------------

- (void)test_getHost_whenNil_returnsEmptyString {
    XCTAssertTrue(_plugin->get_host().is_empty());
}

- (void)test_getHost_customScheme_returnsHost {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];

    XCTAssertEqualObjects(godotStringToNSString(_plugin->get_host()), @"open");
}

- (void)test_getHost_universalLink_returnsDomain {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures universalLinkURL]];

    XCTAssertEqualObjects(godotStringToNSString(_plugin->get_host()), @"example.com");
}

- (void)test_getHost_localhost_returnsLocalhost {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures urlWithExplicitPort]];

    XCTAssertEqualObjects(godotStringToNSString(_plugin->get_host()), @"localhost");
}

// -- get_path -----------------------------------------------------------------

- (void)test_getPath_whenNil_returnsEmptyString {
    XCTAssertTrue(_plugin->get_path().is_empty());
}

- (void)test_getPath_customScheme_returnsPath {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];

    XCTAssertEqualObjects(godotStringToNSString(_plugin->get_path()), @"/product/42");
}

- (void)test_getPath_universalLink_returnsPath {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures universalLinkURL]];

    XCTAssertEqualObjects(godotStringToNSString(_plugin->get_path()), @"/shop/item");
}

- (void)test_getPath_deepPath_returnsFullPath {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures deepPathURL]];

    NSString *path = godotStringToNSString(_plugin->get_path());
    XCTAssertEqualObjects(path, @"/category/electronics/phones/detail");
}

- (void)test_getPath_minimalURL_returnsEmptyPath {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures minimalURL]];

    // NSURL("myapp://home").path is ""
    XCTAssertTrue(_plugin->get_path().is_empty());
}

// -- clear_data ---------------------------------------------------------------

- (void)test_clearData_nillifiesReceivedUrl {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];

    _plugin->clear_data();

    XCTAssertNil(DeeplinkPlugin::receivedUrl);
}

- (void)test_clearData_afterClear_getUrlReturnsEmpty {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];
    _plugin->clear_data();

    XCTAssertTrue(_plugin->get_url().is_empty());
}

- (void)test_clearData_afterClear_getSchemeReturnsEmpty {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];
    _plugin->clear_data();

    XCTAssertTrue(_plugin->get_scheme().is_empty());
}

- (void)test_clearData_afterClear_getHostReturnsEmpty {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];
    _plugin->clear_data();

    XCTAssertTrue(_plugin->get_host().is_empty());
}

- (void)test_clearData_afterClear_getPathReturnsEmpty {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];
    _plugin->clear_data();

    XCTAssertTrue(_plugin->get_path().is_empty());
}

- (void)test_clearData_calledWhenAlreadyNil_doesNotCrash {
    // receivedUrl is already nil from setUp – clear_data must be idempotent.
    XCTAssertNoThrow(_plugin->clear_data());
    XCTAssertNil(DeeplinkPlugin::receivedUrl);
}

// -- is_domain_associated ------------------------------------------------------

- (void)test_isDomainAssociated_alwaysReturnsTrue_iOSStub {
    // iOS implementation is a documented stub that always returns true.
    XCTAssertTrue(_plugin->is_domain_associated("example.com"));
    XCTAssertTrue(_plugin->is_domain_associated("myapp.io"));
    XCTAssertTrue(_plugin->is_domain_associated(""));
}

// -- URL replacement ----------------------------------------------------------

- (void)test_receivedUrl_canBeReplacedWithDifferentURL {
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];
    DeeplinkPlugin::receivedUrl =
        [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures universalLinkURL]];

    XCTAssertEqualObjects(godotStringToNSString(_plugin->get_scheme()), @"https");
}

@end
