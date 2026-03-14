#
# © 2024-present https://github.com/cengiz-pz
#

extends Node

@onready var deeplink := $Deeplink as Deeplink
@onready var _label := %RichTextLabel as RichTextLabel
@onready var _text_edit := %TextEdit as TextEdit
@onready var _android_texture_rect := %AndroidTextureRect as TextureRect
@onready var _ios_texture_rect := %iOSTextureRect as TextureRect

var _active_texture_rect: TextureRect


func _ready() -> void:
	if OS.has_feature("ios"):
		_android_texture_rect.hide()
		_active_texture_rect = _ios_texture_rect
	else:
		_ios_texture_rect.hide()
		_active_texture_rect = _android_texture_rect

	if not deeplink.host.is_empty():
		_text_edit.text = deeplink.host

	deeplink.deeplink_received.connect(_on_deeplink_deeplink_received)

	# check if app link was received at startup
	var __url: String = deeplink.get_link_url()
	if __url != null and not __url.is_empty():
		_print_to_screen(
			(
				"Detected deeplink at startup (URL: %s, scheme: %s, host: %s, path: %s)"
				% [__url, deeplink.get_link_scheme(), deeplink.get_link_host(), deeplink.get_link_path()]
			)
		)


func _on_is_associated_button_pressed() -> void:
	_print_to_screen(
		(
			"Association for domain %s is %s"
			% [_text_edit.text, "valid" if deeplink.is_domain_associated(_text_edit.text) else "invalid"]
		)
	)


func _on_navigate_button_pressed() -> void:
	_print_to_screen("Navigating to 'Open by Default' settings screen")
	deeplink.navigate_to_open_by_default_settings()


func _on_deeplink_deeplink_received(a_url: DeeplinkUrl) -> void:
	_print_to_screen(
		(
			"Deeplink received with scheme: %s, host: %s, path: %s"
			% [a_url.get_scheme(), a_url.get_host(), a_url.get_path()]
		)
	)


func _print_to_screen(a_message: String, a_is_error: bool = false) -> void:
	_label.add_text("%s\n\n" % a_message)
	if a_is_error:
		printerr(a_message)
	else:
		print(a_message)
