extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1:
		fail("Usage: -- <prepared-project> [previous-export-presets] [TEAMID]")
		return
	var target := args[0]
	var project := ConfigFile.new()
	var android := ConfigFile.new()
	var preset := ConfigFile.new()
	if project.load("res://project.godot") != OK or android.load("res://export_presets.cfg") != OK:
		fail("Cannot load canonical configuration")
		return
	if preset.load("res://tools/ios_export_template.cfg") != OK:
		fail("Cannot load iOS template")
		return
	var version: String = project.get_value("application", "config/version")
	var build := str(android.get_value("preset.0.options", "version/code"))
	if args.size() > 1 and FileAccess.file_exists(args[1]):
		var previous := ConfigFile.new()
		if previous.load(args[1]) != OK:
			fail("Cannot read previous iOS settings; refusing to discard signing settings")
			return
		for section in previous.get_sections():
			if previous.get_value(section, "platform", "") != "iOS":
				continue
			var options := section + ".options"
			for key in previous.get_section_keys(options):
				if key.contains("provisioning_profile") or key.contains("code_sign_identity") or key in ["application/app_store_team_id", "application/bundle_identifier"]:
					preset.set_value("preset.0.options", key, previous.get_value(options, key))
			build = str(maxi(int(build), int(previous.get_value(options, "application/version", "0"))))
	if args.size() > 2:
		var regex := RegEx.new()
		regex.compile("^[A-Z0-9]{10}$")
		if regex.search(args[2]) == null:
			fail("Team ID must contain 10 uppercase letters/digits")
			return
		preset.set_value("preset.0.options", "application/app_store_team_id", args[2])
	preset.set_value("preset.0.options", "application/short_version", version)
	preset.set_value("preset.0.options", "application/version", build)
	project.set_value("display", "window/handheld/orientation", 0)
	project.set_value("display", "window/ios/hide_home_indicator", true)
	project.set_value("display", "window/ios/hide_status_bar", true)
	project.set_value("display", "window/ios/suppress_ui_gesture", true)
	project.set_value("display", "window/ios/allow_high_refresh_rate", false)
	if project.save(target.path_join("project.godot")) != OK or preset.save(target.path_join("export_presets.cfg")) != OK:
		fail("Cannot save prepared iOS configuration")
		return
	print("IOS_CONFIG: PASS version=%s build=%s" % [version, build])
	quit()


func fail(message: String) -> void:
	push_error(message)
	quit(1)
