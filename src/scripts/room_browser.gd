extends Control

signal closed

const ThemeKit := preload("res://src/scripts/black_cat_theme.gd")
var rooms: Tree
var status: Label
var refresh_button: Button
var join_button: Button
var create_button: Button
var request: HTTPRequest
var dialog: ConfirmationDialog
var room_name: LineEdit
var password: LineEdit
var password_toggle: CheckButton
var form_status: Label
var creating := false
var selected_code := ""
var _refresh_seconds := 0.0
var _previous_quit_on_back := true


func _ready() -> void:
	_previous_quit_on_back = get_tree().quit_on_go_back
	get_tree().quit_on_go_back = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background := ColorRect.new()
	background.color = ThemeKit.BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	layout.add_child(header)
	var back := make_button("<", Vector2(72, 64))
	back.tooltip_text = "Ana menuye don"
	header.add_child(back)
	back.pressed.connect(_close)
	var title := Label.new()
	title.text = "ONLINE ODALAR | " + ("VS" if GameSession.is_online_vs() else "CO-OP")
	title.add_theme_font_size_override("font_size", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	refresh_button = make_button("YENILE")
	header.add_child(refresh_button)
	refresh_button.pressed.connect(refresh)
	rooms = Tree.new()
	rooms.columns = 4
	rooms.column_titles_visible = true
	rooms.hide_root = true
	rooms.select_mode = Tree.SELECT_ROW
	rooms.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rooms.add_theme_font_size_override("font_size", 24)
	rooms.add_theme_font_size_override("title_button_font_size", 22)
	rooms.add_theme_constant_override("v_separation", 18)
	for index in range(4):
		rooms.set_column_title(index, ["ODA", "OYUNCU", "ERISIM", "DURUM"][index])
		rooms.set_column_expand(index, index == 0)
		rooms.set_column_custom_minimum_width(index, [300, 125, 155, 195][index])
	layout.add_child(rooms)
	rooms.item_selected.connect(_update_join)
	rooms.item_activated.connect(_join_selected)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 22)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 52
	layout.add_child(status)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
	layout.add_child(actions)
	create_button = make_button("ODA OLUSTUR")
	create_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(create_button)
	create_button.pressed.connect(_create)
	join_button = make_button("KATIL")
	join_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_button.disabled = true
	actions.add_child(join_button)
	join_button.pressed.connect(_join_selected)
	request = HTTPRequest.new()
	request.timeout = 8
	request.body_size_limit = 131072
	add_child(request)
	request.request_completed.connect(_listed)
	_build_dialog()
	NetSession.status_changed.connect(_network_status)
	refresh()
	back.grab_focus()


func make_button(text: String, minimum: Vector2 = Vector2(170, 64)) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum
	button.add_theme_font_size_override("font_size", 24)
	ThemeKit.apply_button(button, ThemeKit.ACCENT, ThemeKit.SURFACE)
	return button


func _build_dialog() -> void:
	dialog = ConfirmationDialog.new()
	dialog.dialog_hide_on_ok = false
	dialog.exclusive = true
	var panel_style := ThemeKit.make_panel_style(ThemeKit.SURFACE_ALT, ThemeKit.ACCENT, 8)
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	dialog.add_theme_stylebox_override("panel", panel_style)
	dialog.min_size = Vector2i(620, 370)
	dialog.ok_button_text = "OLUSTUR"
	dialog.cancel_button_text = "VAZGEC"
	add_child(dialog)
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 12)
	dialog.add_child(form)
	room_name = LineEdit.new()
	room_name.placeholder_text = "Oda adi"
	room_name.max_length = 24
	room_name.custom_minimum_size.y = 58
	room_name.add_theme_font_size_override("font_size", 24)
	ThemeKit.apply_line_edit(room_name)
	form.add_child(room_name)
	password_toggle = CheckButton.new()
	password_toggle.text = "Sifreli oda"
	password_toggle.custom_minimum_size.y = 58
	password_toggle.add_theme_font_size_override("font_size", 24)
	form.add_child(password_toggle)
	password_toggle.toggled.connect(func(on: bool): password.visible = on)
	password = LineEdit.new()
	password.placeholder_text = "Oda sifresi"
	password.secret = true
	password.max_length = 64
	password.custom_minimum_size.y = 58
	password.add_theme_font_size_override("font_size", 24)
	ThemeKit.apply_line_edit(password)
	form.add_child(password)
	password.text_submitted.connect(func(_value: String): _submit())
	form_status = Label.new()
	form_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form_status.custom_minimum_size = Vector2(570, 56)
	form_status.add_theme_font_size_override("font_size", 22)
	form.add_child(form_status)
	for button in [dialog.get_ok_button(), dialog.get_cancel_button()]:
		button.custom_minimum_size = Vector2(220, 64)
		button.add_theme_font_size_override("font_size", 24)
		ThemeKit.apply_button(button)
		var padded := ThemeKit.make_button_style(ThemeKit.SURFACE, ThemeKit.ACCENT, 8)
		padded.content_margin_top = 16
		padded.content_margin_bottom = 16
		padded.content_margin_left = 36
		padded.content_margin_right = 36
		button.add_theme_stylebox_override("normal", padded)
	dialog.confirmed.connect(_submit)
	dialog.canceled.connect(_cancel_join)


func _process(delta: float) -> void:
	_refresh_seconds += delta
	if _refresh_seconds >= 8 and not dialog.visible and not _busy():
		refresh()


func refresh() -> void:
	_refresh_seconds = 0
	if refresh_button.disabled:
		return
	refresh_button.disabled = true
	join_button.disabled = true
	status.text = "Odalar yukleniyor..."
	var url := GameSession.get_server_url().replace("wss://", "https://").replace("ws://", "http://")
	url = url.get_slice("://", 0) + "://" + url.get_slice("://", 1).get_slice("/", 0) + "/aksoy-tank/rooms"
	url += "?mode=" + GameSession.get_session_mode().uri_encode() + "&build=" + String(ProjectSettings.get_setting("application/config/version")).uri_encode()
	if request.request(url) != OK:
		refresh_button.disabled = false
		status.text = "Oda listesine ulasilamadi. Yeniden dene."


func _listed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	refresh_button.disabled = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		status.text = "Sunucuya ulasilamadi. Yenile ile tekrar dene."
		return
	var payload = JSON.parse_string(body.get_string_from_utf8())
	if not payload is Dictionary or not payload.get("rooms") is Array:
		status.text = "Oda listesi gecersiz. Yeniden dene."
		return
	var selected := ""
	if rooms.get_selected():
		selected = String(rooms.get_selected().get_metadata(0).get("code", ""))
	rooms.clear()
	var root := rooms.create_item()
	for room in payload["rooms"]:
		if not room is Dictionary or not room.get("code") is String:
			continue
		var row := rooms.create_item(root)
		row.set_text(0, String(room.get("name", "Oda")).substr(0, 24))
		row.set_text(1, "%d / 2" % int(room.get("players", 0)))
		row.set_text(2, "Sifreli" if bool(room.get("locked", false)) else "Acik")
		row.set_text(3, "Macta" if bool(room.get("started", false)) else "Bekliyor")
		row.set_metadata(0, room)
		if room["code"] == selected:
			row.select(0)
	status.text = "Henuz oda yok." if root.get_child_count() == 0 else "%d oda | %s" % [root.get_child_count(), ProjectSettings.get_setting("application/config/version")]
	_update_join()


func _update_join() -> void:
	var row := rooms.get_selected()
	join_button.disabled = row == null or _busy() or refresh_button.disabled
	if row:
		var room: Dictionary = row.get_metadata(0)
		join_button.disabled = join_button.disabled or bool(room.get("started", false)) or int(room.get("players", 2)) >= 2


func _create() -> void:
	if _busy():
		return
	creating = true
	selected_code = ""
	room_name.show()
	room_name.text = GameSession.get_player_name() + " Odasi"
	password_toggle.show()
	password_toggle.set_pressed_no_signal(false)
	password.hide()
	password.text = ""
	form_status.text = ""
	dialog.title = "ODA OLUSTUR"
	dialog.ok_button_text = "OLUSTUR"
	dialog.get_ok_button().disabled = false
	dialog.popup_centered()
	room_name.grab_focus()


func _join_selected() -> void:
	if join_button.disabled:
		return
	var room: Dictionary = rooms.get_selected().get_metadata(0)
	creating = false
	selected_code = String(room["code"])
	password.text = ""
	if not bool(room.get("locked", false)):
		_connect("")
		return
	room_name.hide()
	password_toggle.hide()
	password.show()
	form_status.text = ""
	dialog.title = String(room.get("name", "ODA"))
	dialog.ok_button_text = "KATIL"
	dialog.get_ok_button().disabled = false
	dialog.popup_centered()
	password.grab_focus()


func _submit() -> void:
	if _busy():
		return
	if creating and room_name.text.strip_edges().length() < 3:
		form_status.text = "Oda adi en az 3 karakter olmali."
		return
	var secret := password.text if not creating or password_toggle.button_pressed else ""
	if creating and password_toggle.button_pressed and secret.length() < 4:
		form_status.text = "Sifre en az 4 karakter olmali."
		return
	_connect(secret)


func _connect(secret: String) -> void:
	NetSession.connect_browser_room(GameSession.get_server_url(), GameSession.get_session_mode(), selected_code, secret, room_name.text if creating else "")


func _busy() -> bool:
	return NetSession.get_status() in [NetSession.STATUS_CONNECTING, NetSession.STATUS_JOINING, NetSession.STATUS_RECONNECTING]


func _network_status(_state: String, message: String) -> void:
	status.text = message
	form_status.text = message
	create_button.disabled = _busy()
	dialog.get_ok_button().disabled = _busy()
	_update_join()


func _cancel_join() -> void:
	password.text = ""
	NetSession.disconnect_session()


func _close() -> void:
	request.cancel_request()
	NetSession.disconnect_session()
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not dialog.visible:
		get_viewport().set_input_as_handled()
		_close()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_node_ready():
		if dialog.visible:
			dialog.hide()
			_cancel_join()
		else:
			_close()


func _exit_tree() -> void:
	get_tree().quit_on_go_back = _previous_quit_on_back
