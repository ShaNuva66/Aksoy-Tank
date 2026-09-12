extends SceneTree

var failed := false


func _init() -> void:
	call_deferred("run")


func run() -> void:
	root.gui_embed_subwindows = true
	var session = root.get_node("GameSession")
	var old_mode: String = session.session_mode
	session.session_mode = "online_vs"
	var menu = load("res://src/scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await create_timer(0.5).timeout
	menu.start_button.pressed.emit()
	var browser = menu._room_browser
	check(is_instance_valid(browser), "Online button did not open room browser")
	browser.request.cancel_request()
	browser._listed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), JSON.stringify({"rooms": [
		{"code": "TEST1234", "name": "Atalay Odasi", "players": 1, "locked": true, "started": false},
		{"code": "TEST5678", "name": "Herkese Acik Arena", "players": 1, "locked": false, "started": false},
		{"code": "TEST9999", "name": "Uzun Bir Oda Adi Denemesi", "players": 2, "locked": true, "started": true}
	]}).to_utf8_buffer())
	await process_frame
	check(browser.rooms.get_root().get_child_count() == 3, "Room rows are missing")
	browser.rooms.get_root().get_child(2).select(0)
	browser._update_join()
	check(browser.join_button.disabled, "A started room can be joined")
	browser.rooms.get_root().get_child(0).select(0)
	browser._update_join()
	check(not browser.join_button.disabled, "Waiting room is not joinable")
	await capture("browser-list")
	browser.join_button.pressed.emit()
	check(browser.dialog.visible and browser.password.secret, "Protected room did not prompt for a masked password")
	root.get_node("NetSession")._fail_connection("Oda sifresi yanlis.")
	check(browser.dialog.visible and not browser.dialog.get_ok_button().disabled, "Wrong password closed the form or blocked retry")
	await capture("browser-password")
	browser.dialog.hide()
	browser.create_button.pressed.emit()
	browser.room_name.text = "a"
	browser._submit()
	check(browser.form_status.text.contains("3 karakter"), "Invalid room name was accepted")
	browser.room_name.text = "Test Odasi"
	browser.password_toggle.button_pressed = true
	browser.password.text = "ab"
	browser._submit()
	check(browser.form_status.text.contains("4 karakter"), "Short room password was accepted")
	browser.password.text = "test-secret"
	await capture("browser-create")
	browser.dialog.hide()
	browser._listed(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())
	check(browser.status.text.contains("ulasilamadi"), "Network failure is not visible")
	browser._listed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), '{"rooms":[]}'.to_utf8_buffer())
	check(browser.status.text == "Henuz oda yok." and browser.join_button.disabled, "Empty state is incorrect")
	browser._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await process_frame
	check(not is_instance_valid(menu._room_browser), "Browser did not close")
	menu.queue_free()
	await process_frame
	session.session_mode = old_mode
	print("ROOM_BROWSER: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)


func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)


func capture(label: String) -> void:
	await create_timer(0.2).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://%s-%d.png" % [label, root.size.x])
