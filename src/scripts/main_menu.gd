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
@onready var stage_detail_label: Label = $CenterContainer/Panel/Margin/VBox/StageDetailLabel
@onready var progress_label: Label = $CampaignProgressLabel
@onready var credits_label: Label = $CreditsLabel
@onready var previous_mode_button: Button = $ModeRow/PrevModeButton
@onready var next_mode_button: Button = $ModeRow/NextModeButton
@onready var session_mode_label: Label = $ModeRow/SessionModeLabel
@onready var online_config: VBoxContainer = $CenterContainer/Panel/Margin/VBox/OnlineConfig
@onready var room_label: Label = $CenterContainer/Panel/Margin/VBox/OnlineConfig/RoomRow/RoomLabel
@onready var room_code_edit: LineEdit = $CenterContainer/Panel/Margin/VBox/OnlineConfig/RoomRow/RoomCodeEdit
@onready var server_label: Label = $CenterContainer/Panel/Margin/VBox/OnlineConfig/ServerRow/ServerLabel
@onready var server_url_edit: LineEdit = $CenterContainer/Panel/Margin/VBox/OnlineConfig/ServerRow/ServerUrlEdit
@onready var online_status_label: Label = $CenterContainer/Panel/Margin/VBox/OnlineConfig/OnlineStatusLabel
@onready var reset_progress_button: Button = $CenterContainer/Panel/Margin/VBox/ResetProgressButton
@onready var delete_confirm_dialog: ConfirmationDialog = $DeleteConfirmDialog
@onready var delete_confirm_final_dialog: ConfirmationDialog = $DeleteConfirmFinalDialog

var _stage_title_tween: Tween
var _start_button_pulse_tween: Tween
var _subtitle_pulse_tween: Tween
var _title_glow_tween: Tween
var _button_feedback_tweens: Dictionary = {}


func _ready() -> void:
	_apply_black_cat_theme()
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
	server_label.add_theme_color_override("font_color", BlackCatTheme.MUTED)
	online_status_label.add_theme_color_override("font_color", BlackCatTheme.MUTED)

	for button in [start_button, reset_progress_button, previous_stage_button, next_stage_button, previous_mode_button, next_mode_button]:
		var accent := BlackCatTheme.ACCENT if button == start_button else BlackCatTheme.border_mix(BlackCatTheme.ACCENT, BlackCatTheme.TEXT, 0.18)
		BlackCatTheme.apply_button(button, accent, BlackCatTheme.SURFACE)

	BlackCatTheme.apply_line_edit(room_code_edit)
	BlackCatTheme.apply_line_edit(server_url_edit)


func _start_menu_animations() -> void:
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
	for button in [start_button, reset_progress_button, previous_stage_button, next_stage_button, previous_mode_button, next_mode_button]:
		button.button_down.connect(_on_menu_button_down.bind(button))
		button.button_up.connect(_on_menu_button_up.bind(button))


func _on_menu_button_down(button: Button) -> void:
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
	if event is InputEventKey and event.pressed and not event.echo:
		if room_code_edit.has_focus() or server_url_edit.has_focus():
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
	if GameSession.is_online_mode():
		start_button.disabled = true
		online_status_label.text = "Sunucuya baglaniliyor..."
		NetSession.connect_to_room(GameSession.get_server_url(), GameSession.get_room_code(), GameSession.get_session_mode())
		return

	get_tree().change_scene_to_file("res://src/scenes/prototype_arena.tscn")


func _on_previous_stage_button_pressed() -> void:
	GameSession.shift_stage(-1)
	_refresh_stage_info()


func _on_next_stage_button_pressed() -> void:
	GameSession.shift_stage(1)
	_refresh_stage_info()


func _on_previous_mode_button_pressed() -> void:
	GameSession.shift_session_mode(-1)
	_refresh_stage_info()


func _on_next_mode_button_pressed() -> void:
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


func _on_net_status_changed(_state: String, message: String) -> void:
	online_status_label.text = message
	start_button.disabled = GameSession.is_online_mode() and NetSession.get_status() in [NetSession.STATUS_CONNECTING, NetSession.STATUS_JOINING]


func _on_room_joined(_room_code: String, _role: String, _slot: int) -> void:
	get_tree().change_scene_to_file("res://src/scenes/prototype_arena.tscn")


func _refresh_stage_info() -> void:
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
	server_url_edit.text = GameSession.get_server_url()
	online_config.visible = GameSession.is_online_mode()
	previous_stage_button.disabled = stage["index"] <= 0
	next_stage_button.disabled = stage["index"] >= unlocked_count - 1
	previous_mode_button.disabled = GameSession.get_session_mode() == "solo"
	next_mode_button.disabled = GameSession.get_session_mode() == "online_vs"
	if GameSession.is_online_vs():
		start_button.text = "VS ODASINA GIR"
	elif GameSession.is_online_coop():
		start_button.text = "CO-OP ODASINA GIR"
	else:
		start_button.text = "OPERASYONU BASLAT"
	start_button.disabled = GameSession.is_online_mode() and NetSession.get_status() in [NetSession.STATUS_CONNECTING, NetSession.STATUS_JOINING]
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
