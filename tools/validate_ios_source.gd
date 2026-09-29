extends SceneTree

var failed := false


func _initialize() -> void:
	var preset := ConfigFile.new()
	check(preset.load("res://export_presets.cfg") == OK, "Export settings load")
	check(preset.get_value("preset.0", "platform", "") == "iOS", "iOS preset")
	var options := "preset.0.options"
	check(preset.get_value(options, "application/short_version", "") == ProjectSettings.get_setting("application/config/version"), "Game and export versions match")
	check(preset.get_value(options, "architectures/arm64", false), "arm64 enabled")
	check(preset.get_value(options, "application/min_ios_version", "") == "15.0", "iOS 15 minimum")
	check(not preset.get_value(options, "privacy/tracking_enabled", true), "Tracking disabled")
	check(preset.get_value(options, "entitlements/push_notifications", "") == "Disabled", "Push notifications explicitly disabled")
	check(preset.get_value(options, "application/export_project_only", false), "Project-only export")
	check(ProjectSettings.has_setting("autoload/AudioManager"), "Audio autoload present")
	check(ProjectSettings.get_setting("display/window/handheld/orientation", -1) == 0, "Landscape orientation")
	var game = load("res://src/scripts/game_session.gd")
	check(game.DEFAULT_SERVER_URL == "wss://atify.com.tr/aksoy-tank/ws", "Production TLS endpoint")
	var texture := load("res://assets/store/icons/ios-app-icon-1024.png") as Texture2D
	var icon := texture.get_image() if texture != null else null
	check(icon != null and icon.get_size() == Vector2i(1024, 1024), "1024px iOS icon")
	if icon != null:
		check(icon.detect_alpha() == Image.ALPHA_NONE, "Opaque iOS icon")
	var signing: String = preset.get_value(options, "application/app_store_team_id", "")
	print("IOS_SIGNING: %s" % ("NOT_CONFIGURED" if signing in ["", "YOURTEAMID"] else "TEAM_SET_NOT_VERIFIED"))
	print("IOS_SOURCE_CHECK: %s (not a native iOS build/device test)" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)


func check(condition: bool, label: String) -> void:
	if not condition:
		failed = true
		push_error(label)
