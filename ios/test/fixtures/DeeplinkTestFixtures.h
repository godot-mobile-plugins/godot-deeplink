//
// © 2024-present https://github.com/cengiz-pz
//

#ifndef DeeplinkTestFixtures_h
#define DeeplinkTestFixtures_h

#import <Foundation/Foundation.h>

// ---------------------------------------------------------------------------
// DeeplinkTestFixtures
//
// A single, authoritative source of canned NSURL values used across every
// test suite.  Adding a new URL scenario here makes it available everywhere
// with zero duplication.
//
// Naming convention:
//   <descriptor>URL         – returns a live NSURL instance
//   <descriptor>String      – returns the raw string used to build the URL
// ---------------------------------------------------------------------------

@interface DeeplinkTestFixtures : NSObject

// -- Custom-scheme URLs -------------------------------------------------------

/// myapp://open/product/42?ref=banner&utm_source=email
+ (NSURL *)customSchemeURL;
+ (NSString *)customSchemeAbsoluteString;

/// myapp://home   (minimal – no path, query, or fragment)
+ (NSURL *)minimalURL;

/// myapp://dashboard/   (trailing slash – empty path extension)
+ (NSURL *)trailingSlashURL;

// -- Universal-link (HTTPS) URLs ----------------------------------------------

/// https://example.com/shop/item?id=99#reviews
+ (NSURL *)universalLinkURL;

/// https://example.com/   (root only)
+ (NSURL *)rootUniversalLinkURL;

// -- Authenticated URLs -------------------------------------------------------

/// myapp://alice:s3cr3t@secure/profile
+ (NSURL *)urlWithCredentials;

// -- Port URLs ----------------------------------------------------------------

/// http://localhost:8080/api/v1/ping
+ (NSURL *)urlWithExplicitPort;

// -- File-extension URLs ------------------------------------------------------

/// myapp://media/files/photo.jpg
+ (NSURL *)urlWithFileExtension;

// -- Deep-path URLs -----------------------------------------------------------

/// myapp://store/category/electronics/phones/detail?sku=XYZ#specs
+ (NSURL *)deepPathURL;

// -- NSUserActivity helpers ---------------------------------------------------

/// Returns an NSUserActivity of type NSUserActivityTypeBrowsingWeb whose
/// webpageURL is set to +universalLinkURL.
+ (NSUserActivity *)browsingWebActivity;

/// Returns an NSUserActivity with a non-browsing activity type.
+ (NSUserActivity *)nonBrowsingActivity;

@end

#endif /* DeeplinkTestFixtures_h */
