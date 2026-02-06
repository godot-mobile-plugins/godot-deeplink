//
// © 2024-present https://github.com/cengiz-pz
//

#import "deeplink_url.h"

#import "gdp_converter.h"

static String const kSchemeProperty = "scheme";
static String const kUserProperty = "user";
static String const kPasswordProperty = "password";
static String const kHostProperty = "host";
static String const kPortProperty = "port";
static String const kPathProperty = "path";
static String const kPathExtensionProperty = "path_extension";
static String const kPathComponentsProperty = "path_components";
static String const kQueryProperty = "query";
static String const kFragmentProperty = "fragment";


@implementation DeeplinkUrl

- (instancetype) initWithNsUrl:(NSURL*) nsUrl {
	self = [super init];
	if (self) {
		_absoluteString = nsUrl.absoluteString;
		_scheme = nsUrl.scheme;
		_user = nsUrl.user;
		_password = nsUrl.password;
		_host = nsUrl.host;
		_port = nsUrl.port;
		_path = nsUrl.path;
		_pathExtension = nsUrl.pathExtension;
		_pathComponents = nsUrl.pathComponents;
		_query = nsUrl.query;
		_fragment = nsUrl.fragment;
	}
	return self;
}

- (Dictionary) buildRawData {
	Dictionary dictionary;

	dictionary[kSchemeProperty] = [self.scheme UTF8String];
	dictionary[kUserProperty] = [self.user UTF8String];
	dictionary[kPasswordProperty] = [self.password UTF8String];
	dictionary[kHostProperty] = [self.host UTF8String];
	dictionary[kPortProperty] = [self.port intValue];
	dictionary[kPathProperty] = [self.path UTF8String];
	dictionary[kPathExtensionProperty] = [self.pathExtension UTF8String];
	dictionary[kPathComponentsProperty] = [GDPConverter nsArrayToGodotArray:self.pathComponents];
	dictionary[kQueryProperty] = [self.query UTF8String];
	dictionary[kFragmentProperty] = [self.fragment UTF8String];

	return dictionary;
}

@end
