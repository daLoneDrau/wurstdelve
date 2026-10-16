class_name PaletteLayer
extends CanvasLayer

const SHADER: Shader = preload("res://addons/gdeng/daLoneDrau-GDEng-ECS/shaders/palette_limiter.gdshader")
const PALETTE: Texture2D = preload("res://addons/gdeng/daLoneDrau-GDEng-ECS/shaders/palettes/dawnbringer-32-1x.png")

func _ready() -> void:
	layer = 100
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("palette", PALETTE)
	rect.material = mat
	add_child(rect)
