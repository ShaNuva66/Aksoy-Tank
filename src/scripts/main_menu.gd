extends Control

const BlackCatTheme := preload("res://src/scripts/black_cat_theme.gd")

@onready var background: ColorRect = $Background
@onready var menu_panel: PanelContainer = $CenterContainer/Panel
@onready var title_label: Label = $CenterContainer/Panel/Margin/VBox/Title
@onready var subtitle_label: Label = $CenterContainer/Panel/Margin/VBox/Subtitle
@onready var start_button: Button = $CenterContainer/Panel/Margin/VBox/StartButton
@onready var mode_row: HBoxContainer = $ModeRow
@onready var previous_stage_button: Button = $CenterContainer/Panel/Margin/VBox/StageRow/PrevStageButton
@onready var next_stage_button: Button = $CenterContainer/Panel/Margin/VBox/StageRow/NextStageButton
@onready var stage_title_label: Label = $CenterContainer/Panel/Margin/VBox/StageRow/StageTitleLabel
@onready var stage_row: HBoxContainer = $CenterContainer/Panel/Margin/VBox/StageRow
@onready var stage_detail_label: Label = $CenterContainer/Panel/Margin/VBox/StageDetailLabel
@onready var progress_label: Label = $CampaignProgressLabel
@onready var credits_label: Label = $CreditsLabel
@onready var previous_mode_button: Button = $ModeRow/PrevModeButton
@onready var next_mode_button: Button = $ModeRow/NextModeButton
@onready var session_mode_label: Label = $ModeRow/SessionModeLabel
@onready var online_config: VBoxContainer = $CenterContainer/Panel/Margin/VBox/OnlineConfig
@onready var room_label: Label = $CenterContainer/Panel/Margin/VBox/OnlineConfig/RoomRow/RoomLabel
@onready var room_code_edit: LineEdit = $CenterContainer/Panel/Margin/VBox/OnlineConfig/RoomRow/RoomCodeEdit
@onready var server_row: HBoxContainer = $CenterContainer/Panel/Margin/VBox/OnlineConfig/ServerRow
@onready var server_label: Label = $CenterContainer/Panel/Margin/VBox/OnlineConfig/ServerRow/ServerLabel
@onready var server_url_edit: LineEdit = $CenterContainer/Panel/Margin/VBox/OnlineConfig/ServerRow/ServerUrlEdit
@onready var online_status_label: Label = $CenterContainer/Panel/Margin/VBox/OnlineConfig/OnlineStatusLabel
@onready var player_name_label: Label = $CenterContainer/Panel/Margin/VBox/OnlineConfig/ProfileCard/ProfileFields/NameRow/NameLabel
@onready var player_name_edit: LineEdit = $CenterContainer/Panel/Margin/VBox/OnlineConfig/ProfileCard/ProfileFields/NameRow/PlayerNameEdit
@onready var style_caption: Label = $CenterContainer/Panel/Margin/VBox/OnlineConfig/ProfileCard/ProfileFields/StyleRow/StyleCaption
@onready var style_label: Label = $CenterContainer/Panel/Margin/VBox/OnlineConfig/ProfileCard/ProfileFields/StyleRow/StyleLabel
@onready var previous_style_button: Button = $CenterContainer/Panel/Margin/VBox/OnlineConfig/ProfileCard/ProfileFields/StyleRow/PrevStyleButton
@onready var next_style_button: Button = $CenterContainer/Panel/Margin/VBox/OnlineConfig/ProfileCard/ProfileFields/StyleRow/NextStyleButton
@onready var tank_preview: Control = $CenterContainer/Panel/Margin/VBox/OnlineConfig/ProfileCard/TankPreview
@onready var reset_progress_button: Button = $CenterContainer/Panel/Margin/VBox/ResetProgressButton
@onready var delete_confirm_dialog: ConfirmationDialog = $DeleteConfirmDialog
@onready var delete_confirm_final_dialog: ConfirmationDialog = $DeleteConfirmFinalDialog

var _stage_title_tween: Tween
var _start_button_pulse_tween: Tween
var _subtitle_pulse_tween: Tween
var _title_glow_tween: Tween
var _button_feedback_tweens: Dictionary = {}
var _settings_button: Button
var _settings_overlay: Control
var _settings_panel: PanelContainer
var _music_slider: HSlider
var _sfx_slider: HSlider
var _effects_slider: HSlider
var _haptics_toggle: CheckButton
var _reduced_motion_toggle: CheckButton
var _privacy_button: Button
var _settings_close_button: Button
var _quick_match_button: Button
var _mode_buttons: Dictionary = {}
var _room_browser: Control
var _control_buttons: Dictionary = {}


func _ready() -> void:
	_install_settings_ui()
	_install_quick_match_button()
	_apply_black_cat_theme()
	_install_mobile_navigation()
	_install_control_selection()
	room_code_edit.get_parent().hide()
	mode_row.visible = GameSession.is_online_available()
	server_row.visible = false
	server_url_edit.editable = false
	start_button.pressed.connect(_on_start_button_pressed)
	previous_stage_button.pressed.connect(_on_previous_stage_button_pressed)
	next_stage_button.pressed.connect(_on_next_stage_button_pressed)
	previous_mode_button.pressed.connect(_on_previous_mode_button_pressed)
	next_mode_button.pressed.connect(_on_next_mode_button_pressed)
	reset_progress_button.pressed.connect(_on_reset_progress_button_pressed)
	delete_confirm_dialog.confirmed.connect(_on_delete_confirm_dialog_confirmed)
	delete_confirm_final_dialog.confirmed.connect(_on_delete_confirm_final_dialog_confirmed)
	_connect_button_feedback()
	room_code_edit.text_changed.connect(_on_room_code_changed)
	player_name_edit.text_changed.connect(_on_player_name_changed)
	previous_style_button.pressed.connect(_on_previous_style_pressed)
	next_style_button.pressed.connect(_on_next_style_pressed)
	server_url_edit.text_changed.connect(_on_server_url_changed)
	GameSession.progress_changed.connect(_refresh_stage_info)
	NetSession.status_changed.connect(_on_net_status_changed)
	NetSession.room_joined.connect(_on_room_joined)
	_configure_confirm_dialog(delete_confirm_dialog, "Kaydedilen veriyi sil", "Emin misin?")
	_configure_confirm_dialog(delete_confirm_final_dialog, "Son onay", "Gercekten emin misin? Hepsi silinecek.")
	_refresh_stage_info()
	_on_net_status_changed(NetSession.get_status(), NetSession.get_status_message())
	_start_menu_animations()
	if _has_launch_argument("--auto-start"):
		call_deferred("_on_start_button_pressed")


func _apply_black_cat_theme() -> void:
	background.color = BlackCatTheme.BACKGROUND
	menu_panel.add_theme_stylebox_override("panel", BlackCatTheme.make_panel_style(BlackCatTheme.SURFACE_ALT, BlackCatTheme.border_mix(BlackCatTheme.SURFACE_ALT, BlackCatTheme.ACCENT, 0.24), 32, 2))
	title_label.add_theme_color_override("font_color", BlackCatTheme.ACCENT_SOFT)
	subtitle_label.add_theme_color_override("font_color", BlackCatTheme.MUTED)
	stage_title_label.add_theme_color_override("font_color", BlackCatTheme.TEXT)
	stage_detail_label.add_theme_color_override("font_color", BlackCatTheme.MUTED)
	progress_label.add_theme_color_override("font_color", BlackCatTheme.ACCENT)
	credits_label.add_theme_color_override("font_color", BlackCatTheme.MUTED.darkened(0.08))
	session_mode_label.add_theme_color_override("font_color", BlackCatTheme.ACCENT)
	room_label.add_theme_color_override("font_color", BlackCatTheme.MUTED)
	player_name_label.add_theme_color_override("font_color", BlackCatTheme.MUTED)
	style_caption.add_theme_color_override("font_color", BlackCatTheme.MUTED)
	style_label.add_theme_color_override("font_color", BlackCatTheme.ACCENT_SOFT)
	server_label.add_theme_color_override("font_color", BlackCatTheme.MUTED)
	online_status_label.add_theme_color_override("font_color", BlackCatTheme.MUTED)

	for button in [start_button, reset_progress_button, previous_stage_button, next_stage_button, previous_mode_button, next_mode_button, previous_style_button, next_style_button, _settings_button, _privacy_button, _settings_close_button, _quick_match_button]:
		var accent := BlackCatTheme.ACCENT if button == start_button else BlackCatTheme.border_mix(BlackCatTheme.ACCENT, BlackCatTheme.TEXT, 0.18)
		BlackCatTheme.apply_button(button, accent, BlackCatTheme.SURFACE)

	BlackCatTheme.apply_line_edit(room_code_edit)
	BlackCatTheme.apply_line_edit(player_name_edit)
	BlackCatTheme.apply_line_edit(server_url_edit)
	_settings_panel.add_theme_stylebox_override("panel", BlackCatTheme.make_panel_style(BlackCatTheme.SURFACE_ALT, BlackCatTheme.border_mix(BlackCatTheme.SURFACE_ALT, BlackCatTheme.ACCENT, 0.3), 8, 2))


func _install_mobile_navigation() -> void:
	stage_title_label.add_theme_font_size_override("font_size", 26)
	stage_detail_label.add_theme_font_size_override("font_size", 20)
	progress_label.add_theme_font_size_override("font_size", 20)
	previous_mode_button.hide()
	next_mode_button.hide()
	session_mode_label.hide()
	var group := ButtonGroup.new()
	for mode in ["solo", "online_coop", "online_vs"]:
		var button := Button.new()
		button.text = {"solo": "HIKAYE", "online_coop": "CO-OP", "online_vs": "VS"}[mode]
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(144, 64)
		button.add_theme_font_size_override("font_size", 24)
		BlackCatTheme.apply_button(button, BlackCatTheme.ACCENT, BlackCatTheme.SURFACE)
		button.pressed.connect(_select_mode.bind(mode))
		mode_row.add_child(button)
		_mode_buttons[mode] = button
	for button in [previous_stage_button, next_stage_button, previous_style_button, next_style_button]:
		button.custom_minimum_size = Vector2(72, 64)
		button.add_theme_font_size_override("font_size", 26)
	for control in [room_code_edit, player_name_edit]:
		control.custom_minimum_size.y = 58
		control.add_theme_font_size_override("font_size", 24)
	_quick_match_button.custom_minimum_size.y = 64
	_quick_match_button.add_theme_font_size_override("font_size", 24)
	_settings_button.custom_minimum_size = Vector2(140, 64)
	_settings_button.offset_bottom = 82
	_settings_button.add_theme_font_size_override("font_size", 24)
	start_button.custom_minimum_size.y = 72
	$CenterContainer.offset_top = 88
	$CenterContainer.offset_bottom = -44
	title_label.add_theme_font_size_override("font_size", 34)
	subtitle_label.hide()
	menu_panel.custom_minimum_size.x = 780
	var margin := $CenterContainer/Panel/Margin
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	$CenterContainer/Panel/Margin/VBox.add_theme_constant_override("separation", 12)


func _install_control_selection() -> void:
	var row := HBoxContainer.new()
	row.name = "ControlSelection"
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = "KONTROL"
	label.custom_minimum_size.x = 140
	label.add_theme_font_size_override("font_size", 22)
	row.add_child(label)
	var group := ButtonGroup.new()
	for style in ["analog", "buttons"]:
		var button := Button.new()
		button.text = "ANALOG" if style == "analog" else "YON BUTONLARI"
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(220, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 22)
		BlackCatTheme.apply_button(button, BlackCatTheme.ACCENT, BlackCatTheme.SURFACE)
		button.pressed.connect(GameSession.set_control_style.bind(style))
		row.add_child(button)
		_control_buttons[style] = button
	var column := $CenterContainer/Panel/Margin/VBox
	column.add_child(row)
	column.move_child(row, start_button.get_index())


func _select_mode(mode: String) -> void:
	NetSession.disconnect_session()
	GameSession.set_session_mode(mode)
	_refresh_stage_info()


func _start_menu_animations() -> void:
	if GameSession.is_reduced_motion_enabled():
		_stop_menu_motion()
		return
	call_deferred("_run_menu_intro")


func _run_menu_intro() -> void:
	var intro_controls: Array[Control] = [
		mode_row,
		menu_panel,
		progress_label,
		credits_label,
	]
	var intro_tween := create_tween()
	intro_tween.set_parallel(true)
	intro_tween.finished.connect(_start_looping_menu_animations)

	for index in range(intro_controls.size()):
		var control := intro_controls[index]
		if control == null or not control.visible:
			continue

		_prepare_intro_control(control)
		var target_modulate := control.modulate
		target_modulate.a = 1.0
		var delay := float(index) * 0.08
		intro_tween.tween_property(control, "modulate", target_modulate, 0.34).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		intro_tween.tween_property(control, "scale", Vector2.ONE, 0.42).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _prepare_intro_control(control: Control) -> void:
	_set_control_pivot(control)
	var invisible := control.modulate
	invisible.a = 0.0
	control.modulate = invisible
	control.scale = Vector2(0.94, 0.94)


func _start_looping_menu_animations() -> void:
	_set_control_pivot(title_label)
	_set_control_pivot(subtitle_label)
	_set_control_pivot(start_button)
	_start_title_glow()
	_start_subtitle_pulse()
	_start_start_button_pulse(0.28)


func _start_title_glow() -> void:
	if _title_glow_tween and _title_glow_tween.is_valid():
		_title_glow_tween.kill()

	title_label.modulate = Color.WHITE
	_title_glow_tween = create_tween()
	_title_glow_tween.set_loops()
	_title_glow_tween.tween_property(title_label, "modulate", Color(1.0, 0.96, 0.78, 1.0), 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_title_glow_tween.tween_property(title_label, "modulate", Color.WHITE, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _start_subtitle_pulse() -> void:
	if _subtitle_pulse_tween and _subtitle_pulse_tween.is_valid():
		_subtitle_pulse_tween.kill()

	_subtitle_pulse_tween = _create_scale_loop(subtitle_label, Vector2(1.035, 1.035), 0.78)


func _start_start_button_pulse(delay: float = 0.0) -> void:
	if _start_button_pulse_tween and _start_button_pulse_tween.is_valid():
		_start_button_pulse_tween.kill()

	_start_button_pulse_tween = _create_scale_loop(start_button, Vector2(1.025, 1.025), 0.9, delay)


func _create_scale_loop(control: Control, peak_scale: Vector2, duration: float, delay: float = 0.0) -> Tween:
	_set_control_pivot(control)
	var tween := create_tween()
	tween.set_loops()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(control, "scale", peak_scale, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween


func _connect_button_feedback() -> void:
	for button in [start_button, reset_progress_button, previous_stage_button, next_stage_button, previous_mode_button, next_mode_button, _settings_button, _privacy_button, _settings_close_button, _quick_match_button]:
		button.button_down.connect(_on_menu_button_down.bind(button))
		button.button_up.connect(_on_menu_button_up.bind(button))


func _install_settings_ui() -> void:
	_settings_button = Button.new()
	_settings_button.name = "SettingsButton"
	_settings_button.text = "AYARLAR"
	_settings_button.tooltip_text = "Ses ve titreşim ayarları"
	_settings_button.anchor_left = 1.0
	_settings_button.anchor_right = 1.0
	_settings_button.offset_left = -164.0
	_settings_button.offset_top = 18.0
	_settings_button.offset_right = -24.0
	_settings_button.offset_bottom = 62.0
	_settings_button.pressed.connect(_open_settings)
	add_child(_settings_button)

	_settings_overlay = Control.new()
	_settings_overlay.name = "SettingsOverlay"
	_settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.z_index = 30
	_settings_overlay.visible = false
	add_child(_settings_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.015, 0.02, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.add_child(center)

	_settings_panel = PanelContainer.new()
	_settings_panel.custom_minimum_size = Vector2(600.0, 0.0)
	var settings_theme := Theme.new()
	settings_theme.default_font_size = 26
	_settings_panel.theme = settings_theme
	center.add_child(_settings_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 28)
	_settings_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	var title := Label.new()
	title.text = "AYARLAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", BlackCatTheme.ACCENT_SOFT)
	column.add_child(title)
	_music_slider = _add_volume_row(column, "MÜZİK", GameSession.get_music_volume())
	_sfx_slider = _add_volume_row(column, "EFEKTLER", GameSession.get_sfx_volume())
	_effects_slider = _add_volume_row(column, "GÖRSEL EFEKT", GameSession.get_effects_intensity())
	_haptics_toggle = CheckButton.new()
	_haptics_toggle.text = "TİTREŞİM"
	_haptics_toggle.button_pressed = GameSession.is_haptics_enabled()
	_haptics_toggle.toggled.connect(GameSession.set_haptics_enabled)
	column.add_child(_haptics_toggle)
	_reduced_motion_toggle = CheckButton.new()
	_reduced_motion_toggle.text = "HAREKETİ AZALT"
	_reduced_motion_toggle.button_pressed = GameSession.is_reduced_motion_enabled()
	_reduced_motion_toggle.toggled.connect(_on_reduced_motion_toggled)
	column.add_child(_reduced_motion_toggle)
	_privacy_button = Button.new()
	_privacy_button.text = "GİZLİLİK POLİTİKASI"
	_privacy_button.pressed.connect(func(): OS.shell_open("https://atify.com.tr/aksoy-tank/privacy"))
	column.add_child(_privacy_button)
	_settings_close_button = Button.new()
	_settings_close_button.text = "TAMAM"
	_settings_close_button.pressed.connect(_close_settings)
	column.add_child(_settings_close_button)
	for control in [_haptics_toggle, _reduced_motion_toggle, _privacy_button, _settings_close_button]:
		control.custom_minimum_size.y = 56
		control.add_theme_font_size_override("font_size", 26)
	_music_slider.value_changed.connect(func(value: float): GameSession.set_music_volume(value / 100.0))
	_sfx_slider.value_changed.connect(func(value: float): GameSession.set_sfx_volume(value / 100.0))
	_effects_slider.value_changed.connect(func(value: float): GameSession.set_effects_intensity(value / 100.0))
	_sfx_slider.drag_ended.connect(func(changed: bool):
		if changed:
			var audio_manager := get_node_or_null("/root/AudioManager")
			if audio_manager:
				audio_manager.play_sfx("pickup", 1.0, 0.65)
	)


func _install_quick_match_button() -> void:
	_quick_match_button = Button.new()
	_quick_match_button.name = "QuickMatchButton"
	_quick_match_button.text = "HIZLI EŞLEŞ"
	_quick_match_button.custom_minimum_size = Vector2(0.0, 50.0)
	_quick_match_button.pressed.connect(_on_quick_match_pressed)
	online_config.add_child(_quick_match_button)


func _add_volume_row(parent: VBoxContainer, label_text: String, value: float) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(190.0, 0.0)
	label.add_theme_font_size_override("font_size", 26)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", BlackCatTheme.TEXT)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 5.0
	slider.value = value * 100.0
	slider.custom_minimum_size = Vector2(280.0, 42.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	return slider


func _open_settings() -> void:
	_music_slider.set_value_no_signal(GameSession.get_music_volume() * 100.0)
	_sfx_slider.set_value_no_signal(GameSession.get_sfx_volume() * 100.0)
	_effects_slider.set_value_no_signal(GameSession.get_effects_intensity() * 100.0)
	_haptics_toggle.set_pressed_no_signal(GameSession.is_haptics_enabled())
	_reduced_motion_toggle.set_pressed_no_signal(GameSession.is_reduced_motion_enabled())
	_settings_overlay.visible = true


func _close_settings() -> void:
	_settings_overlay.visible = false


func _on_reduced_motion_toggled(enabled: bool) -> void:
	GameSession.set_reduced_motion_enabled(enabled)
	if enabled:
		_stop_menu_motion()
	else:
		_start_menu_animations()


func _stop_menu_motion() -> void:
	for tween in [_start_button_pulse_tween, _subtitle_pulse_tween, _title_glow_tween, _stage_title_tween]:
		if tween and tween.is_valid():
			tween.kill()
	for control in [mode_row, menu_panel, progress_label, credits_label, title_label, subtitle_label, start_button]:
		if control:
			control.scale = Vector2.ONE
			control.modulate = Color.WHITE


func _on_menu_button_down(button: Button) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_ui()
	if button == start_button and _start_button_pulse_tween and _start_button_pulse_tween.is_valid():
		_start_button_pulse_tween.kill()
	_animate_button_scale(button, Vector2(0.94, 0.94), 0.08)


func _on_menu_button_up(button: Button) -> void:
	_animate_button_scale(button, Vector2.ONE, 0.12)
	if button == start_button:
		call_deferred("_start_start_button_pulse", 0.18)


func _animate_button_scale(button: Button, target_scale: Vector2, duration: float) -> void:
	_set_control_pivot(button)
	if _button_feedback_tweens.has(button):
		var old_tween: Tween = _button_feedback_tweens[button]
		if old_tween and old_tween.is_valid():
			old_tween.kill()

	var tween := create_tween()
	_button_feedback_tweens[button] = tween
	tween.tween_property(button, "scale", target_scale, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _animate_stage_title_refresh() -> void:
	if not is_inside_tree():
		return
	call_deferred("_run_stage_title_refresh")


func _run_stage_title_refresh() -> void:
	_set_control_pivot(stage_title_label)
	if _stage_title_tween and _stage_title_tween.is_valid():
		_stage_title_tween.kill()

	stage_title_label.scale = Vector2(1.08, 1.08)
	stage_title_label.modulate = Color(1.0, 0.92, 0.62, 1.0)
	_stage_title_tween = create_tween()
	_stage_title_tween.set_parallel(true)
	_stage_title_tween.tween_property(stage_title_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_stage_title_tween.tween_property(stage_title_label, "modulate", Color.WHITE, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _set_control_pivot(control: Control) -> void:
	if control == null:
		return
	control.pivot_offset = control.size * 0.5


func _exit_tree() -> void:
	if NetSession.status_changed.is_connected(_on_net_status_changed):
		NetSession.status_changed.disconnect(_on_net_status_changed)
	if NetSession.room_joined.is_connected(_on_room_joined):
		NetSession.room_joined.disconnect(_on_room_joined)


func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_room_browser):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if _settings_overlay.visible:
			if event.keycode == KEY_ESCAPE:
				_close_settings()
			return
		if room_code_edit.has_focus() or server_url_edit.has_focus() or player_name_edit.has_focus():
			return

		if event.keycode == KEY_LEFT:
			_on_previous_stage_button_pressed()
			return

		if event.keycode == KEY_RIGHT:
			_on_next_stage_button_pressed()
			return

		if event.keycode == KEY_UP:
			_on_next_mode_button_pressed()
			return

		if event.keycode == KEY_DOWN:
			_on_previous_mode_button_pressed()
			return

		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_on_start_button_pressed()


func _on_start_button_pressed() -> void:
	if is_instance_valid(_room_browser):
		return
	if start_button.disabled:
		return
	if GameSession.is_online_mode():
		if GameSession.get_player_name().length() < 3:
			online_status_label.text = "Oyuncu adı en az 3 karakter olmalı."
			player_name_edit.grab_focus()
			return
		_room_browser = preload("res://src/scripts/room_browser.gd").new()
		add_child(_room_browser)
		return

	get_tree().change_scene_to_file("res://src/scenes/prototype_arena.tscn")


func _on_quick_match_pressed() -> void:
	if _quick_match_button.disabled or not GameSession.is_online_mode():
		return
	if GameSession.get_player_name().length() < 3:
		online_status_label.text = "Oyuncu adı en az 3 karakter olmalı."
		player_name_edit.grab_focus()
		return
	start_button.disabled = true
	_quick_match_button.disabled = true
	online_status_label.text = "Uygun oyuncu aranıyor..."
	NetSession.connect_matchmaking(GameSession.get_server_url(), GameSession.get_session_mode())


func _on_previous_stage_button_pressed() -> void:
	GameSession.shift_stage(-1)
	_refresh_stage_info()


func _on_next_stage_button_pressed() -> void:
	GameSession.shift_stage(1)
	_refresh_stage_info()


func _on_previous_mode_button_pressed() -> void:
	if NetSession.get_status() != NetSession.STATUS_DISCONNECTED:
		NetSession.disconnect_session()
	GameSession.shift_session_mode(-1)
	_refresh_stage_info()


func _on_next_mode_button_pressed() -> void:
	if NetSession.get_status() != NetSession.STATUS_DISCONNECTED:
		NetSession.disconnect_session()
	GameSession.shift_session_mode(1)
	_refresh_stage_info()


func _on_reset_progress_button_pressed() -> void:
	delete_confirm_dialog.popup_centered()


func _on_delete_confirm_dialog_confirmed() -> void:
	delete_confirm_final_dialog.popup_centered()


func _on_delete_confirm_final_dialog_confirmed() -> void:
	GameSession.reset_progress()


func _on_room_code_changed(new_text: String) -> void:
	GameSession.set_room_code(new_text)
	if room_code_edit.text != GameSession.get_room_code():
		room_code_edit.text = GameSession.get_room_code()
		room_code_edit.caret_column = room_code_edit.text.length()


func _on_server_url_changed(new_text: String) -> void:
	GameSession.set_server_url(new_text)


func _on_player_name_changed(new_text: String) -> void:
	GameSession.set_player_name(new_text)
	if player_name_edit.text != GameSession.get_player_name():
		player_name_edit.text = GameSession.get_player_name()
		player_name_edit.caret_column = player_name_edit.text.length()


func _on_previous_style_pressed() -> void:
	GameSession.shift_tank_style(-1)


func _on_next_style_pressed() -> void:
	GameSession.shift_tank_style(1)


func _on_net_status_changed(_state: String, message: String) -> void:
	online_status_label.text = message
	var busy := GameSession.is_online_mode() and NetSession.get_status() in [NetSession.STATUS_CONNECTING, NetSession.STATUS_JOINING, NetSession.STATUS_RECONNECTING]
	start_button.disabled = busy
	_quick_match_button.disabled = busy


func _on_room_joined(joined_room_code: String, _role: String, _slot: int) -> void:
	GameSession.set_room_code(joined_room_code)
	get_tree().change_scene_to_file("res://src/scenes/prototype_arena.tscn")


func _refresh_stage_info() -> void:
	for style in _control_buttons:
		_control_buttons[style].set_pressed_no_signal(style == GameSession.get_control_style())
	for mode in _mode_buttons:
		_mode_buttons[mode].set_pressed_no_signal(mode == GameSession.get_session_mode())
	var stage: Dictionary = GameSession.get_selected_stage()
	var unlocked_count := GameSession.get_unlocked_stage_count()

	if not GameSession.is_online_mode() and NetSession.get_status() != NetSession.STATUS_DISCONNECTED:
		NetSession.disconnect_session()

	stage_title_label.text = "SEVIYE %02d / %02d  |  %s" % [stage["number"], stage["total_stages"], stage["name"]]
	var objective_label := String(stage.get("objective_label", "Tum dusmanlari temizle."))
	stage_detail_label.text = "%s  |  Hedef: %s" % [stage.get("tagline", "Ozgun savunma duzeni."), objective_label]
	progress_label.text = "Campaign %d/%d" % [unlocked_count, stage["total_stages"]]
	session_mode_label.text = GameSession.get_session_mode_label()
	room_code_edit.text = GameSession.get_room_code()
	if player_name_edit.text != GameSession.get_player_name():
		player_name_edit.text = GameSession.get_player_name()
	var tank_style := GameSession.get_tank_style()
	style_label.text = String(tank_style.get("label", "AKINCI"))
	if tank_preview.has_method("set_profile"):
		tank_preview.set_profile(GameSession.get_network_profile())
	server_url_edit.text = GameSession.get_server_url()
	online_config.visible = GameSession.is_online_mode()
	stage_row.visible = not GameSession.is_online_vs()
	reset_progress_button.visible = not GameSession.is_online_mode()
	previous_stage_button.disabled = stage["index"] <= 0
	next_stage_button.disabled = stage["index"] >= unlocked_count - 1
	previous_mode_button.disabled = not GameSession.is_online_available() or GameSession.get_session_mode() == "solo"
	next_mode_button.disabled = not GameSession.is_online_available() or GameSession.get_session_mode() == "online_vs"
	if GameSession.is_online_vs():
		start_button.text = "VS ODALARI"
	elif GameSession.is_online_coop():
		start_button.text = "CO-OP ODALARI"
	else:
		start_button.text = "OPERASYONU BASLAT"
	var busy := GameSession.is_online_mode() and NetSession.get_status() in [NetSession.STATUS_CONNECTING, NetSession.STATUS_JOINING, NetSession.STATUS_RECONNECTING]
	start_button.disabled = busy
	_quick_match_button.disabled = busy
	_animate_stage_title_refresh()


func _configure_confirm_dialog(dialog: ConfirmationDialog, title_text: String, body_text: String) -> void:
	dialog.title = title_text
	dialog.dialog_text = body_text
	dialog.ok_button_text = "Evet"
	var cancel_button := dialog.get_cancel_button()
	if cancel_button:
		cancel_button.text = "Vazgec"


func _has_launch_argument(expected: String) -> bool:
	for argument in OS.get_cmdline_user_args():
		if argument == expected:
			return true
	return false
