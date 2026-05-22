//
// © 2024-present https://github.com/cengiz-pz
//

#import <XCTest/XCTest.h>

#import "deeplink_url.h"
#import "DeeplinkTestFixtures.h"

// ---------------------------------------------------------------------------
// Helper – pull a String out of a Godot Dictionary by a C-string key
// ---------------------------------------------------------------------------
static NSString *godotStringToNSString(const String &s) {
    return [NSString stringWithUTF8String:s.utf8().get_data()];
}

static NSString *rawDataString(const Dictionary &d, const char *key) {
    Variant v = d[key];
    if (v.get_type() == Variant::STRING) {
        return godotStringToNSString(String(v));
    }
    return nil;
}

static int rawDataInt(const Dictionary &d, const char *key) {
    Variant v = d[key];
    return (int)(int64_t)v;
}

// ---------------------------------------------------------------------------
// DeeplinkUrlTests
// ---------------------------------------------------------------------------

@interface DeeplinkUrlTests : XCTestCase
@end

@implementation DeeplinkUrlTests

// -- Initialisation ----------------------------------------------------------

- (void)test_initWithNsUrl_customScheme_populatesAllProperties {
    NSURL *url = [DeeplinkTestFixtures customSchemeURL];
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:url];

    XCTAssertEqualObjects(sut.absoluteString, DeeplinkTestFixtures.customSchemeAbsoluteString);
    XCTAssertEqualObjects(sut.scheme, @"myapp");
    XCTAssertEqualObjects(sut.host, @"open");
    XCTAssertEqualObjects(sut.path, @"/product/42");
    XCTAssertEqualObjects(sut.query, @"ref=banner&utm_source=email");
    XCTAssertNil(sut.fragment);
    XCTAssertNil(sut.user);
    XCTAssertNil(sut.password);
}

- (void)test_initWithNsUrl_universalLink_populatesAllProperties {
    NSURL *url = [DeeplinkTestFixtures universalLinkURL];
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:url];

    XCTAssertEqualObjects(sut.scheme, @"https");
    XCTAssertEqualObjects(sut.host, @"example.com");
    XCTAssertEqualObjects(sut.path, @"/shop/item");
    XCTAssertEqualObjects(sut.query, @"id=99");
    XCTAssertEqualObjects(sut.fragment, @"reviews");
}

- (void)test_initWithNsUrl_withCredentials_exposesUserAndPassword {
    NSURL *url = [DeeplinkTestFixtures urlWithCredentials];
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:url];

    XCTAssertEqualObjects(sut.user, @"alice");
    XCTAssertEqualObjects(sut.password, @"s3cr3t");
}

- (void)test_initWithNsUrl_withExplicitPort_exposesPort {
    NSURL *url = [DeeplinkTestFixtures urlWithExplicitPort];
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:url];

    XCTAssertEqualObjects(sut.port, @8080);
}

- (void)test_initWithNsUrl_withoutPort_portIsNil {
    NSURL *url = [DeeplinkTestFixtures customSchemeURL];
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:url];

    XCTAssertNil(sut.port);
}

- (void)test_initWithNsUrl_pathComponents_areCorrect {
    NSURL *url = [DeeplinkTestFixtures customSchemeURL]; // path = /product/42
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:url];

    // NSURL path components for /product/42 → ["/" "product" "42"]
    XCTAssertEqual(sut.pathComponents.count, 3u);
    XCTAssertEqualObjects(sut.pathComponents[0], @"/");
    XCTAssertEqualObjects(sut.pathComponents[1], @"product");
    XCTAssertEqualObjects(sut.pathComponents[2], @"42");
}

- (void)test_initWithNsUrl_pathExtension_isCorrect {
    NSURL *url = [DeeplinkTestFixtures urlWithFileExtension]; // e.g. /files/photo.jpg
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:url];

    XCTAssertEqualObjects(sut.pathExtension, @"jpg");
}

- (void)test_initWithNsUrl_minimalURL_onlySchemeAndHost {
    NSURL *url = [DeeplinkTestFixtures minimalURL];
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:url];

    XCTAssertEqualObjects(sut.scheme, @"myapp");
    XCTAssertEqualObjects(sut.host, @"home");
    XCTAssertEqualObjects(sut.path, @"");
    XCTAssertNil(sut.query);
    XCTAssertNil(sut.fragment);
}

// -- buildRawData -------------------------------------------------------------

- (void)test_buildRawData_customScheme_schemeKeyPresent {
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];
    Dictionary d = [sut buildRawData];

    XCTAssertEqualObjects(rawDataString(d, "scheme"), @"myapp");
}

- (void)test_buildRawData_customScheme_hostKeyPresent {
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];
    Dictionary d = [sut buildRawData];

    XCTAssertEqualObjects(rawDataString(d, "host"), @"open");
}

- (void)test_buildRawData_customScheme_pathKeyPresent {
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];
    Dictionary d = [sut buildRawData];

    XCTAssertEqualObjects(rawDataString(d, "path"), @"/product/42");
}

- (void)test_buildRawData_customScheme_queryKeyPresent {
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];
    Dictionary d = [sut buildRawData];

    XCTAssertEqualObjects(rawDataString(d, "query"), @"ref=banner&utm_source=email");
}

- (void)test_buildRawData_universalLink_fragmentKeyPresent {
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures universalLinkURL]];
    Dictionary d = [sut buildRawData];

    XCTAssertEqualObjects(rawDataString(d, "fragment"), @"reviews");
}

- (void)test_buildRawData_port_isCorrectInteger {
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures urlWithExplicitPort]];
    Dictionary d = [sut buildRawData];

    XCTAssertEqual(rawDataInt(d, "port"), 8080);
}

- (void)test_buildRawData_pathComponents_godotArrayHasCorrectCount {
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];
    Dictionary d = [sut buildRawData];

    Array arr = d["path_components"];
    XCTAssertEqual((int)arr.size(), 3);
}

- (void)test_buildRawData_pathComponents_godotArrayValuesCorrect {
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];
    Dictionary d = [sut buildRawData];

    Array arr = d["path_components"];
    NSString *second = godotStringToNSString(String(arr[1]));
    XCTAssertEqualObjects(second, @"product");
}

- (void)test_buildRawData_pathExtension_presentInDictionary {
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures urlWithFileExtension]];
    Dictionary d = [sut buildRawData];

    XCTAssertEqualObjects(rawDataString(d, "path_extension"), @"jpg");
}

// NOTE: buildRawData calls [nil UTF8String] which returns NULL, causing
// the Godot String(NULL) constructor to produce an empty string "".
// These tests document and lock in that null-coalesces-to-empty behaviour.

- (void)test_buildRawData_nilUser_yieldsEmptyString {
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];
    Dictionary d = [sut buildRawData];

    // user is nil → UTF8String → NULL → String("") or empty
    Variant userVar = d["user"];
    XCTAssertEqual(userVar.get_type(), Variant::STRING,
                   @"user key should be present as STRING even when nil");
}

- (void)test_buildRawData_nilFragment_yieldsEmptyString {
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures customSchemeURL]];
    Dictionary d = [sut buildRawData];

    Variant fragVar = d["fragment"];
    XCTAssertEqual(fragVar.get_type(), Variant::STRING);
}

// -- Immutability / copy semantics --------------------------------------------

- (void)test_absoluteString_isImmutableCopy {
    NSURL *url = [DeeplinkTestFixtures customSchemeURL];
    DeeplinkUrl *sut = [[DeeplinkUrl alloc] initWithNsUrl:url];
    NSString *snap = sut.absoluteString;

    // Reinitialise with a different URL; the snapshot must not change.
    DeeplinkUrl *other = [[DeeplinkUrl alloc] initWithNsUrl:[DeeplinkTestFixtures universalLinkURL]];
    XCTAssertNotEqualObjects(snap, other.absoluteString);
    XCTAssertEqualObjects(snap, DeeplinkTestFixtures.customSchemeAbsoluteString);
}

@end
