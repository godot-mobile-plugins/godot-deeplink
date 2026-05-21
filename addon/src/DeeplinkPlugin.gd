#
# © 2024-present https://github.com/cengiz-pz
#

@tool
extends EditorPlugin

const PLUGIN_NAME: String = "@pluginName@"
const ANDROID_DEPENDENCIES: Array = [ @androidDependencies@ ]
const IOS_FRAMEWORKS: Array = [ @iosFrameworks@ ]
const IOS_EMBEDDED_FRAMEWORKS: Array = [ @iosEmbeddedFrameworks@ ]
const IOS_LINKER_FLAGS: Array = [ @iosLinkerFlags@ ]

var android_export_plugin: AndroidExportPlugin
var ios_export_plugin: IosExportPlugin


func _enter_tree() -> void:
	android_export_plugin = AndroidExportPlugin.new()
	add_export_plugin(android_export_plugin)
	ios_export_plugin = IosExportPlugin.new()
	add_export_plugin(ios_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(android_export_plugin)
	android_export_plugin = null
	remove_export_plugin(ios_export_plugin)
	ios_export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	var _plugin_name = PLUGIN_NAME
	var _export_config: DeeplinkExportConfig

	const DEEPLINK_ACTIVITY_FORMAT = """
		<activity
			android:name="@activityClass@"
			android:theme="@android:style/Theme.Translucent.NoTitleBar.Fullscreen"
			android:excludeFromRecents="true"
			android:launchMode="singleTask"
			android:exported="true"
			android:noHistory="true">

			%s
		</activity>
"""

	const DEEPLINK_INTENT_FILTER_FORMAT = """
			<intent-filter android:label="%s" %s>
				<action android:name="android.intent.action.VIEW" />
				%s
				%s
				<data android:scheme="%s"
					android:host="%s"
					android:pathPrefix="%s" />
			</intent-filter>
"""

	const DEEPLINK_INTENT_FILTER_WITHOUT_HOST_FORMAT = """
			<intent-filter android:label="%s" %s>
				<action android:name="android.intent.action.VIEW" />
				%s
				%s
				<data android:scheme="%s"
					android:pathPrefix="%s" />
			</intent-filter>
"""

	const DEEPLINK_INTENT_FILTER_AUTO_VERIFY_PROPERTY = "android:autoVerify=\"true\""
	const DEEPLINK_INTENT_FILTER_DEFAULT_CATEGORY = "<category android:name=\"android.intent.category.DEFAULT\" />"
	const DEEPLINK_INTENT_FILTER_BROWSABLE_CATEGORY = "<category android:name=\"android.intent.category.BROWSABLE\" />"


	func _supports_platform(platform: EditorExportPlatform) -> bool:
		if platform is EditorExportPlatformAndroid:
			return true
		return false


	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if debug:
			return PackedStringArray(["%s/bin/debug/%s-debug.aar" % [_plugin_name, _plugin_name]])
		else:
			return PackedStringArray(["%s/bin/release/%s-release.aar" % [_plugin_name, _plugin_name]])


	func _get_name() -> String:
		return _plugin_name


	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
		_export_config = DeeplinkExportConfig.new()
		if not _export_config.export_config_file_exists() or _export_config.load_export_config_from_file() != OK:
			_export_config.load_export_config_from_node(Deeplink.Platform.Android)


	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray(ANDROID_DEPENDENCIES)


	func _get_android_manifest_application_element_contents(platform: EditorExportPlatform, debug: bool) -> String:
		var __filters: String = ""

		for __config in _export_config.deeplinks:
			if __config.host.is_empty():
				__filters += DEEPLINK_INTENT_FILTER_WITHOUT_HOST_FORMAT % [
							__config.label,
							DEEPLINK_INTENT_FILTER_AUTO_VERIFY_PROPERTY if __config.is_auto_verify else "",
							DEEPLINK_INTENT_FILTER_DEFAULT_CATEGORY if __config.is_default else "",
							DEEPLINK_INTENT_FILTER_BROWSABLE_CATEGORY if __config.is_browsable else "",
							__config.scheme,
							__config.path_prefix
						]
			else:
				__filters += DEEPLINK_INTENT_FILTER_FORMAT % [
							__config.label,
							DEEPLINK_INTENT_FILTER_AUTO_VERIFY_PROPERTY if __config.is_auto_verify else "",
							DEEPLINK_INTENT_FILTER_DEFAULT_CATEGORY if __config.is_default else "",
							DEEPLINK_INTENT_FILTER_BROWSABLE_CATEGORY if __config.is_browsable else "",
							__config.scheme,
							__config.host,
							__config.path_prefix
						]

		return DEEPLINK_ACTIVITY_FORMAT % __filters


class IosExportPlugin extends EditorExportPlugin:
	var _plugin_name = PLUGIN_NAME
	var _export_path: String
	var _export_config: DeeplinkExportConfig

	const ENTITLEMENTS_FILE_HEADER: String = """<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>com.apple.developer.associated-domains</key>
		<array>\n"""

	const ENTITLEMENTS_FILE_FOOTER: String = """\t</array>
	</dict>
	</plist>\n"""
	const EXPORT_FILE_SUFFIX: String = ".ipa"

	const UNIVERSAL_LINK_SCHEMES: Array[String] = ["http", "https"]

	const CUSTOM_SCHEME_PLIST_ENTRY: String = """
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLName</key>
			<string>%s</string>
			<key>CFBundleURLSchemes</key>
			<array>
				%s
			</array>
		</dict>
	</array>
	"""

	const CUSTOM_SCHEME_ARRAY_ITEM: String = """
				<string>%s</string>
	"""

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		if platform is EditorExportPlatformIOS:
			return true
		return false


	func _get_name() -> String:
		return _plugin_name


	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
		_export_path = path

		_export_config = DeeplinkExportConfig.new()
		if not _export_config.export_config_file_exists() or _export_config.load_export_config_from_file() != OK:
			_export_config.load_export_config_from_node(Deeplink.Platform.iOS)

		# Compile a list of configured custom schemes
		var __custom_schemes: String = ""
		for __config in _export_config.deeplinks:
			if __config.scheme.to_lower() not in UNIVERSAL_LINK_SCHEMES:
				__custom_schemes += CUSTOM_SCHEME_ARRAY_ITEM % __config.scheme
				Deeplink.log_info("Adding custom scheme '%s'." % __config.scheme)

		# Add custom schemes to pList
		if not __custom_schemes.is_empty():
			add_apple_embedded_platform_plist_content(
				CUSTOM_SCHEME_PLIST_ENTRY % [get_option("application/bundle_identifier"), __custom_schemes]
			)

		for __framework in IOS_FRAMEWORKS:
			add_apple_embedded_platform_framework(__framework)

		for __framework in IOS_EMBEDDED_FRAMEWORKS:
			add_apple_embedded_platform_embedded_framework(__framework)

		for __flag in IOS_LINKER_FLAGS:
			add_apple_embedded_platform_linker_flags(__flag)


	func _export_end() -> void:
		_regenerate_entitlements_file()


	func _export_directory_path_for_entitlements(a_export_path: String) -> String:
		var __directory_path := a_export_path.trim_suffix(EXPORT_FILE_SUFFIX)
		if __directory_path.is_absolute_path():
			return ProjectSettings.globalize_path(__directory_path)
		return ProjectSettings.globalize_path("res://" + __directory_path)


	func _regenerate_entitlements_file() -> void:
		if _export_path:
			if _export_path.ends_with(EXPORT_FILE_SUFFIX):
				var __directory_path = _export_directory_path_for_entitlements(_export_path)
				if DirAccess.dir_exists_absolute(__directory_path):
					var __project_name = _get_project_name_from_path(__directory_path)
					var __file_path = "%s/%s.entitlements" % [__directory_path, __project_name]
					Deeplink.log_info("******** ENTITLEMENTS FILE PATH='%s'" % __file_path)
					if FileAccess.file_exists(__file_path):
						DirAccess.remove_absolute(__file_path)
					var __file = FileAccess.open(__file_path, FileAccess.WRITE)
					if __file:
						__file.store_string(ENTITLEMENTS_FILE_HEADER)

						for __config in _export_config.deeplinks:
							__file.store_line("\t\t<string>applinks:%s</string>" % __config.host)
							# As opposed to Android, in iOS __config.scheme, __config.path_prefix are
							# configured on the server side for Universal Links (apple-app-site-association file)

						__file.store_string(ENTITLEMENTS_FILE_FOOTER)
						__file.close()
					else:
						Deeplink.log_error("Couldn't open file '%s' for writing." % __file_path)
				else:
					Deeplink.log_error("Directory '%s' doesn't exist." % __directory_path)
			else:
				Deeplink.log_error("Unexpected export path '%s'" % _export_path)
		else:
			Deeplink.log_error("Export path is not defined.")


	func _get_project_name_from_path(a_path: String) -> String:
		var __result = ""

		var __split = a_path.rsplit("/", false, 1)
		if __split.size() > 1:
			__result = __split[1]

		return __result
