//
// © 2024-present https://github.com/cengiz-pz
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "deeplink_plugin.h"
#import "deeplink_service.h"
#import "deeplink_logger.h"
#import "gdp_converter.h"


String const DEEPLINK_RECEIVED_SIGNAL = "deeplink_received";

DeeplinkPlugin* DeeplinkPlugin::instance = NULL;
DeeplinkUrl* DeeplinkPlugin::receivedUrl;


void DeeplinkPlugin::_bind_methods() {
	ClassDB::bind_method(D_METHOD("initialize"), &DeeplinkPlugin::initialize);
	ClassDB::bind_method(D_METHOD("get_url"), &DeeplinkPlugin::get_url);
	ClassDB::bind_method(D_METHOD("get_scheme"), &DeeplinkPlugin::get_scheme);
	ClassDB::bind_method(D_METHOD("get_host"), &DeeplinkPlugin::get_host);
	ClassDB::bind_method(D_METHOD("get_path"), &DeeplinkPlugin::get_path);
	ClassDB::bind_method(D_METHOD("clear_data"), &DeeplinkPlugin::clear_data);
	ClassDB::bind_method(D_METHOD("is_domain_associated"), &DeeplinkPlugin::is_domain_associated);
	ClassDB::bind_method(D_METHOD("navigate_to_open_by_default_settings"), &DeeplinkPlugin::navigate_to_open_by_default_settings);

	ADD_SIGNAL(MethodInfo(DEEPLINK_RECEIVED_SIGNAL, PropertyInfo(Variant::DICTIONARY, "url_data")));
}

Error DeeplinkPlugin::initialize() {
	os_log_debug(deeplink_log, "DeeplinkPlugin initialize");

	if (initialized) {
		os_log_debug(deeplink_log, "DeeplinkPlugin already initialized");
		return FAILED;
	}

	if (receivedUrl) {
		emit_signal(DEEPLINK_RECEIVED_SIGNAL, [receivedUrl buildRawData]);
	}

	initialized = true;

	return OK;
}

String DeeplinkPlugin::get_url() {
	String result = "";

	if (receivedUrl) {
		result = [GDPConverter nsStringToGodotString:receivedUrl.absoluteString];
	}

	return result;
}

String DeeplinkPlugin::get_scheme() {
	String result = "";

	if (receivedUrl) {
		result = [GDPConverter nsStringToGodotString:receivedUrl.scheme];
	}

	return result;
}

String DeeplinkPlugin::get_host() {
	String result = "";

	if (receivedUrl) {
		result = [GDPConverter nsStringToGodotString:receivedUrl.host];
	}

	return result;
}

String DeeplinkPlugin::get_path() {
	String result = "";

	if (receivedUrl) {
		result = [GDPConverter nsStringToGodotString:receivedUrl.path];
	}

	return result;
}

void DeeplinkPlugin::clear_data() {
	receivedUrl = NULL;
}

bool DeeplinkPlugin::is_domain_associated(String domain) {
	os_log_error(deeplink_log, "ERROR: DeeplinkPlugin::is_domain_associated: method is not implemented for iOS!");
	return true;
}

void DeeplinkPlugin::navigate_to_open_by_default_settings() {
	if (@available(iOS 18.3, *)) {
		// Create and navigate to the URL that deep links to app's custom settings.
		NSURL *url = [[NSURL alloc] initWithString:UIApplicationOpenDefaultApplicationsSettingsURLString];
		[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
	}
	else if (@available(iOS 8.0, *)) {
		// Create and navigate to the URL that deep links to app's settings.
		NSURL *url = [[NSURL alloc] initWithString:UIApplicationOpenSettingsURLString];
		[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
	}
	else {
		os_log_debug(deeplink_log, "DeeplinkPlugin::navigate_to_open_by_default_settings: ERROR: iOS version 8.0 or greater is required!");
	}
}

DeeplinkPlugin* DeeplinkPlugin::get_singleton() {
	return instance;
}

DeeplinkPlugin::DeeplinkPlugin() {
	os_log_debug(deeplink_log, "DeeplinkPlugin constructor");

	ERR_FAIL_COND(instance != NULL);
	instance = this;

	initialized = false;
}

DeeplinkPlugin::~DeeplinkPlugin() {
	os_log_debug(deeplink_log, "DeeplinkPlugin destructor");

	if (instance == this) {
		instance = NULL;
	}
}
