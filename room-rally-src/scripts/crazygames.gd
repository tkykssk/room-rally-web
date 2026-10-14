extends Node

## CrazyGames SDK v3 bridge (autoload "CG"). Every call is a no-op when the
## game isn't running in a browser with the SDK loaded, so local runs and
## other hosts behave normally. The SDK script is added to the page by the
## Web export preset (html/head_include).

var _sdk: JavaScriptObject = null
var _ready_sdk: bool = false
var _callbacks: Array = []  # JS callbacks must stay referenced.
var _ad_done: Callable

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):
		return
	var window: = JavaScriptBridge.get_interface("window")
	if window == null or window.CrazyGames == null:
		return
	_sdk = window.CrazyGames.SDK
	_sdk.init().then(_cb(_on_init))

func _cb(method: Callable) -> JavaScriptObject:
	var cb: = JavaScriptBridge.create_callback(method)
	_callbacks.append(cb)
	return cb

func _on_init(_args: Array) -> void:
	_ready_sdk = true
	_apply_mute_setting([])
	_sdk.game.addSettingsChangeListener(_cb(_apply_mute_setting))

## Respect the player's mute toggle on the CrazyGames page.
func _apply_mute_setting(_args: Array) -> void:
	Audio.set_muted(bool(_sdk.game.settings.muteAudio))

func gameplay_start() -> void:
	if _ready_sdk:
		_sdk.game.gameplayStart()

func gameplay_stop() -> void:
	if _ready_sdk:
		_sdk.game.gameplayStop()

func happytime() -> void:
	if _ready_sdk:
		_sdk.game.happytime()

## Show a midgame ad (the SDK rate-limits these), then call `done`.
## Audio is muted and the game paused while the ad plays.
func midgame_ad(done: Callable) -> void:
	if not _ready_sdk:
		done.call()
		return
	_ad_done = done
	var callbacks: JavaScriptObject = JavaScriptBridge.create_object("Object")
	callbacks.adStarted = _cb(_on_ad_started)
	callbacks.adFinished = _cb(_on_ad_finished)
	callbacks.adError = _cb(_on_ad_finished)
	_sdk.ad.requestAd("midgame", callbacks)

func _on_ad_started(_args: Array) -> void:
	Audio.set_muted(true)
	get_tree().paused = true

func _on_ad_finished(_args: Array) -> void:
	get_tree().paused = false
	_apply_mute_setting([])
	if _ad_done.is_valid():
		var done: = _ad_done
		_ad_done = Callable()
		done.call()
