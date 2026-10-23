class_name TitleScene
extends Scene

## Title screen: a 3D background (a .glb shown in a full-screen SubViewport), the game
## logo, and a three-button menu. New Game leads to campaign selection. Load Game stays
## disabled until a saved campaign exists. Options opens as an overlay. Quit is Q-key
## only (no button).

const CAMPAIGN_SELECT_KEY: String = "campaign_select"
const CAMPAIGN_SELECT_PATH: String = "res://game/scenes/campaign_select/campaign_select.tscn"

const LOAD_DISABLED_TEXT: String = "LOAD GAME DISABLED: NO SAVED CAMPAIGN"
const LOAD_ENABLED_TEXT: String = "LOAD GAME: CONTINUE A SAVED CAMPAIGN"
const QUIT_NOTE_TEXT: String = "QUIT: HIDDEN ON WEB BUILD (Q KEY ONLY)"

## The background model (drop a .glb here in the inspector). Instanced under ModelAnchor.
@export var background_model: PackedScene
## Slow turntable spin of the background model, in degrees per second. 0 = still.
@export var spin_degrees_per_second: float = 0.0
## Renders the 3D background at 1/N of 960x540 for a chunkier, low-res look (1 = full).
@export_range(1, 4) var render_shrink: int = 1
## Game logo, 336x96. Assign in the inspector once the art exists.
@export var logo: Texture2D
## Selection arrow shown beside the highlighted menu row. Empty = generated placeholder.
@export var arrow_texture: Texture2D

@onready var _model_stage: SubViewportContainer = %ModelStage
@onready var _model_anchor: Node3D = %ModelAnchor
@onready var _logo: TextureRect = %Logo
@onready var _logo_fallback: Label = %LogoFallback
@onready var _new_game_button: ArrowButton = %NewGameButton
@onready var _load_game_button: ArrowButton = %LoadGameButton
@onready var _options_button: ArrowButton = %OptionsButton
@onready var _load_status_label: Label = %LoadStatusLabel
@onready var _quit_note_label: Label = %QuitNoteLabel

var _model: Node3D

## Menu rows top to bottom, and the action each one runs.
var _menu: Array[ArrowButton] = []
var _menu_actions: Array[String] = ["new_game", "load_game", "options"]
var _selected_index: int = 0


func _ready() -> void:
	_model_stage.stretch_shrink = render_shrink
	if background_model != null:
		_model = background_model.instantiate() as Node3D
		if _model != null:
			_model_anchor.add_child(_model)
	_logo.texture = logo
	_logo_fallback.visible = logo == null
	_quit_note_label.text = QUIT_NOTE_TEXT
	_menu.append(_new_game_button)
	_menu.append(_load_game_button)
	_menu.append(_options_button)
	for button: ArrowButton in _menu:
		if arrow_texture != null:
			button.arrow_texture = arrow_texture
		button.hovered.connect(_on_button_hovered)
	set_process(_model != null and not is_zero_approx(spin_degrees_per_second))


func _process(delta: float) -> void:
	_model_anchor.rotate_y(deg_to_rad(spin_degrees_per_second) * delta)


func on_enter() -> void:
	register_action("Up", "menu_up")
	register_action("Down", "menu_down")
	register_action("Enter", "confirm")
	register_action("N", "new_game")
	register_action("O", "options")
	register_action("Q", "quit")
	_refresh_load_state()
	_select(0)


func do_action(action: GameAction) -> void:
	if not action.is_pressed():
		return
	if not _game_engine.scene_stack.is_empty():
		return   # an overlay (e.g. Options) is open; keys belong to it
	match action.name:
		"menu_up": _move_selection(-1)
		"menu_down": _move_selection(1)
		"confirm": _perform(_menu_actions[_selected_index])
		_: _perform(action.name)


func _perform(action_name: String) -> void:
	match action_name:
		"new_game": _start_new_game()
		"load_game": _load_game()
		"options": _game_engine.push_scene("options")
		"quit": _game_engine.quit()


## Moves the arrow to the next enabled row in `step` direction, wrapping around.
func _move_selection(step: int) -> void:
	for i in _menu.size():
		var candidate: int = posmod(_selected_index + step * (i + 1), _menu.size())
		if not _menu[candidate].disabled:
			_select(candidate)
			return


## Selects a row, or the first enabled row if that one is disabled.
func _select(index: int) -> void:
	if _menu[index].disabled:
		for i in _menu.size():
			if not _menu[i].disabled:
				index = i
				break
	_selected_index = index
	for i in _menu.size():
		_menu[i].selected = (i == _selected_index)


func _on_button_hovered(button: ArrowButton) -> void:
	_select(_menu.find(button))


## Load Game is available only when a saved campaign exists. The "L" key is
## registered only while it is, so a disabled button and its key never disagree.
func _refresh_load_state() -> void:
	var can_load: bool = _has_saved_campaign()
	_load_game_button.disabled = not can_load
	_select(_selected_index)   # a disabled row can't hold the arrow
	_load_status_label.text = LOAD_ENABLED_TEXT if can_load else LOAD_DISABLED_TEXT
	if can_load:
		register_action("L", "load_game")
	else:
		unregister_action("L")


## TODO: ask the save service once campaign saves exist (post-M5). Always false for now.
func _has_saved_campaign() -> bool:
	return false


func _start_new_game() -> void:
	if not ResourceLoader.exists(CAMPAIGN_SELECT_PATH):
		push_warning("TitleScene: campaign selection scene not built yet (%s)" % CAMPAIGN_SELECT_PATH)
		return
	_game_engine.change_scene(CAMPAIGN_SELECT_KEY, CAMPAIGN_SELECT_PATH)


func _load_game() -> void:
	if not _has_saved_campaign():
		return
	print("Load Game (placeholder)")
