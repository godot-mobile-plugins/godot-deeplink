//
// © 2024-present https://github.com/cengiz-pz
//

#ifndef deeplink_url_h
#define deeplink_url_h

#import <Foundation/Foundation.h>

#include "core/object/class_db.h"


@interface DeeplinkUrl : NSObject

@property (copy, readonly) NSString * absoluteString;
@property (copy, readonly) NSString * scheme;
@property (copy, readonly) NSString * user;
@property (copy, readonly) NSString * password;
@property (copy, readonly) NSString * host;
@property (copy, readonly) NSNumber * port;
@property (copy, readonly) NSString * path;
@property (copy, readonly) NSString * pathExtension;
@property (copy, readonly) NSArray<NSString *> * pathComponents;
@property (copy, readonly) NSString * query;
@property (copy, readonly) NSString * fragment;

/**
 * Initializes the wrapper with a NSURL object
 * @param nsUrl The NSURL object
 */
- (instancetype) initWithNsUrl:(NSURL*) nsUrl;

/**
 * Builds a Godot-compatible Dictionary containing the URL data
 * @return A Dictionary object with the NSURL details
 */
- (Dictionary) buildRawData;

@end

#endif /* deeplink_url_h */
