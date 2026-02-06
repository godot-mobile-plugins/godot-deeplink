///
// © 2024-present https://github.com/cengiz-pz
//

#ifndef deeplink_plugin_h
#define deeplink_plugin_h

#include "core/object/object.h"
#include "core/object/class_db.h"

#import "deeplink_url.h"


extern String const DEEPLINK_RECEIVED_SIGNAL;


class DeeplinkPlugin : public Object {
	GDCLASS(DeeplinkPlugin, Object);

private:
	static DeeplinkPlugin* instance;

	bool initialized;

	static void _bind_methods();
	
public:
	static DeeplinkUrl* receivedUrl;
	
	Error initialize();

	String get_url();

	String get_scheme();

	String get_host();

	String get_path();

	void clear_data();

	bool is_domain_associated(String domain);

	void navigate_to_open_by_default_settings();

	static DeeplinkPlugin* get_singleton();
	
	DeeplinkPlugin();
	~DeeplinkPlugin();
};

#endif /* deeplink_plugin_h */
