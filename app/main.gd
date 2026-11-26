## Engine adapter: keeps the clock, passes keys to the Session, and draws what it holds.
## It never decides rules: those live in core/session.gd.
extends Node3D

const GRID := Vector2i(48, 48)  # your call: bigger grids make the dragon feel finer
const TICK_SECONDS := 0.1
const CAMERA_OFFSET := Vector3(0, 11, 7.5)  # above and behind the head
const DIRECTIONS := {
	"ui_up": Vector2i.UP,
	"ui_down": Vector2i.DOWN,
	"ui_left": Vector2i.LEFT,
	"ui_right": Vector2i.RIGHT,
}

var session := Session.new(GRID)
var meshes := {}  # kit piece name -> Mesh, shared by everything that shows it (Flyweight)
var segments: Array[MeshInstance3D] = []
var food_mesh := MeshInstance3D.new()
var score_label := Label.new()
var big_score_label := Label.new()
var camera := Camera3D.new()
var _clock := 0.0


func _ready() -> void:
	meshes = Stage.load_kit()
	_build_stage()
	food_mesh.mesh = meshes["food"]
	score_label.position = Vector2(16, 16)
	big_score_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	big_score_label.add_theme_font_size_override("font_size", 32)
	big_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(big_score_label)
	big_score_label.visible = false
	add_child(food_mesh)
	add_child(score_label)
	_draw_dragon()
	_draw_food()
	_draw_score()
	session.state_changed.connect(state_changed)


## Input arrives as events, so even a tap shorter than one frame is never missed.
func _unhandled_input(event: InputEvent) -> void:
	match session.state:
		Session.State.PLAYING:
			for action in DIRECTIONS:
				if event.is_action_pressed(action):
					session.dragon.turn(DIRECTIONS[action])
		Session.State.READY:
			big_score_label.visible = false
			session.start_game()
		Session.State.GAMEOVER:
			new_session()
			big_score_label.visible = false


func show_big_text() -> void:
	big_score_label.text = "Score %d \n Press any button to restart" % session.score
	big_score_label.visible = true


func _process(delta: float) -> void:
	_clock += delta
	while _clock >= TICK_SECONDS:
		_clock -= TICK_SECONDS
		session.tick()
		_draw_dragon()
		_draw_food()
		_draw_score()
	_follow(delta)


func new_session() -> void:
	session = Session.new(GRID)
	session.state_changed.connect(state_changed)


func state_changed(new_state: Session.State):
	if new_state == Session.State.GAMEOVER:
		show_big_text()


## Sky, light, and tiles live in app/stage.gd; the camera follows the head.
func _build_stage() -> void:
	add_child(Stage.new(session.board.tiles, meshes))
	add_child(camera)
	camera.position = _center(session.dragon.body[0]) + CAMERA_OFFSET


## Ease toward the head each frame, so the camera glides while the dragon steps.
func _follow(delta: float) -> void:
	var target := _center(session.dragon.body[0]) + CAMERA_OFFSET
	camera.position = camera.position.lerp(target, 1 - exp(-3 * delta))
	camera.look_at(camera.position - CAMERA_OFFSET)


func _draw_dragon() -> void:
	var body := session.dragon.body
	while segments.size() < body.size():
		var segment := MeshInstance3D.new()
		add_child(segment)
		segments.append(segment)
	var placed := Kit.layout(body)
	for i in segments.size():
		var segment := segments[i]
		segment.visible = i < body.size()
		if not segment.visible:
			continue
		var cell := body[i]
		segment.mesh = meshes[Kit.Piece.keys()[placed[i][0]].to_lower()]
		segment.position = _center(cell)
		segment.rotation.y = placed[i][1] * PI / 2


func _draw_food() -> void:
	food_mesh.position = _center(session.food)


## The score lives in the Session; this only shows it.
func _draw_score() -> void:
	score_label.text = "Score %d" % session.score


func _center(cell: Vector2i) -> Vector3:
	return Vector3(cell.x + 0.5, 0, cell.y + 0.5)
