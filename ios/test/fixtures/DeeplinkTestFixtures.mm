//
// © 2024-present https://github.com/cengiz-pz
//

#import "DeeplinkTestFixtures.h"

@implementation DeeplinkTestFixtures

// -- Custom-scheme ------------------------------------------------------------

+ (NSString *)customSchemeAbsoluteString {
    return @"myapp://open/product/42?ref=banner&utm_source=email";
}

+ (NSURL *)customSchemeURL {
    return [NSURL URLWithString:[self customSchemeAbsoluteString]];
}

+ (NSURL *)minimalURL {
    return [NSURL URLWithString:@"myapp://home"];
}

+ (NSURL *)trailingSlashURL {
    return [NSURL URLWithString:@"myapp://dashboard/"];
}

// -- Universal-link ------------------------------------------------------------

+ (NSURL *)universalLinkURL {
    return [NSURL URLWithString:@"https://example.com/shop/item?id=99#reviews"];
}

+ (NSURL *)rootUniversalLinkURL {
    return [NSURL URLWithString:@"https://example.com/"];
}

// -- Authenticated ------------------------------------------------------------

+ (NSURL *)urlWithCredentials {
    return [NSURL URLWithString:@"myapp://alice:s3cr3t@secure/profile"];
}

// -- Port ----------------------------------------------------------------------

+ (NSURL *)urlWithExplicitPort {
    return [NSURL URLWithString:@"http://localhost:8080/api/v1/ping"];
}

// -- File extension -----------------------------------------------------------

+ (NSURL *)urlWithFileExtension {
    return [NSURL URLWithString:@"myapp://media/files/photo.jpg"];
}

// -- Deep path ----------------------------------------------------------------

+ (NSURL *)deepPathURL {
    return [NSURL URLWithString:
        @"myapp://store/category/electronics/phones/detail?sku=XYZ#specs"];
}

// -- NSUserActivity helpers ----------------------------------------------------

+ (NSUserActivity *)browsingWebActivity {
    NSUserActivity *activity =
        [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = [self universalLinkURL];
    return activity;
}

+ (NSUserActivity *)nonBrowsingActivity {
    return [[NSUserActivity alloc]
        initWithActivityType:@"com.example.myapp.viewItem"];
}

@end
