//
// © 2025-present https://github.com/cengiz-pz
//

#import "deeplink_logger.h"

// Define and initialize the shared os_log_t instance
os_log_t deeplink_log;

__attribute__((constructor)) // Automatically runs at program startup
static void initialize_deeplink_log(void) {
	deeplink_log = os_log_create("org.godotengine.plugin.deeplink", "DeeplinkPlugin");
}
