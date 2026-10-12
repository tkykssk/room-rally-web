extends Node

var _avg_dt: float = 0.016
var _label: Label
var _ui_t: float = 0.0
var _frame: int = 0
var _elapsed: float = 0.0
var _spikes: int = 0
var _max_dt: float = 0.0
var _last_spike: String = "-"
const WARMUP_GRACE: = 2.5

func _ready() -> void:
	var layer: = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(20, 96)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(1, 1, 0.6))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 4)
	layer.add_child(_label)

func _process(delta: float) -> void:
	_frame += 1
	_elapsed += delta
	_avg_dt = lerp(_avg_dt, delta, 0.05)
	var ms: = delta * 1000.0
	if _elapsed > WARMUP_GRACE and delta > maxf(_avg_dt * 2.5, 0.033):
		_spikes += 1
		_max_dt = maxf(_max_dt, ms)
		_last_spike = "dt:%.0fms draw:%d obj:%d mem:%.1f" % [
			ms,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.OBJECT_COUNT),
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		]
	_ui_t += delta
	if _ui_t >= 0.25 and _label:
		_ui_t = 0.0
		_label.text = "FPS %.0f  draw %d\nobj %d  node %d  mem %.1fMB\nspikes %d  maxdt %.0fms\nlast %s" % [
			Performance.get_monitor(Performance.TIME_FPS),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.OBJECT_COUNT),
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
			_spikes, _max_dt, _last_spike,
		]
