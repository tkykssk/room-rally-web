extends Node

## Keeps 3D rendering cost bounded on high-DPI screens (retina laptops,
## phones): the 3D scene renders at most ~MAX_3D_PIXELS and is upscaled,
## while the UI stays at full resolution. Autoload "RenderQuality".

const MAX_3D_PIXELS: = 1280.0 * 720.0 * 1.2
const MIN_SCALE: = 0.5

func _ready() -> void:
	get_window().size_changed.connect(_apply)
	_apply()

func _apply() -> void:
	var px: = Vector2(get_window().size)
	var area: = maxf(px.x * px.y, 1.0)
	var vp: = get_viewport()
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = clampf(sqrt(MAX_3D_PIXELS / area), MIN_SCALE, 1.0)
