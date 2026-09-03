extends SceneTree

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("NETWORK_RESILIENCE: retry state audit started")
	var net_session := root.get_node_or_null("NetSession")
	if net_session == null:
		_fail("NetSession autoload is missing")
		quit(1)
		return

	net_session.disconnect_session(false)
	net_session._pending_server_url = "wss://atify.com.tr/aksoy-tank/ws"
	net_session._pending_room_code = "TEST01"
	net_session._pending_mode = "online_coop"
	net_session._reconnect_enabled = true
	net_session._joined_once = true
	net_session._role = "guest"
	net_session._local_slot = 2
	net_session._peer_connected = true
	net_session._handle_transport_failure("Test kesintisi.")
	_require(net_session.get_status() == net_session.STATUS_RECONNECTING, "Paired session did not enter reconnect state")
	_require(net_session._pending_room_code == "TEST01" and not net_session._matchmaking, "Paired session lost its private reconnect target")
	_require(net_session._reconnect_attempt == 1 and net_session._reconnect_wait > 0.0, "Reconnect backoff was not scheduled")

	net_session.disconnect_session(false)
	net_session._pending_server_url = "wss://atify.com.tr/aksoy-tank/ws"
	net_session._pending_room_code = "QWAIT01"
	net_session._pending_mode = "online_vs"
	net_session._reconnect_enabled = true
	net_session._joined_once = true
	net_session._joined_via_matchmaking = true
	net_session._peer_connected = false
	net_session._handle_transport_failure("Bekleme kesintisi.")
	_require(net_session.get_status() == net_session.STATUS_RECONNECTING, "Waiting matchmaking session did not retry")
	_require(net_session._matchmaking and net_session._pending_room_code.is_empty(), "Waiting player did not return to matchmaking")

	net_session.disconnect_session(false)
	if _failed:
		print("NETWORK_RESILIENCE: FAIL")
		quit(1)
	else:
		print("NETWORK_RESILIENCE: PASS")
		quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failed = true
	push_error("NETWORK_RESILIENCE FAIL: " + message)
	print("NETWORK_RESILIENCE: FAIL - " + message)
