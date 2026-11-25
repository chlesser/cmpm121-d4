## One run at the game: the board and the dragon on it, from the first tick until the
## run ends. Rules that involve more than the dragon (food, score, what the dragon can
## run into) belong here, so Dragon stays about movement and app/ only draws.
class_name Session
extends RefCounted

const GROWTH_PER_FOOD := 1  # body cells added per bite
const RNG_SEED := 121  # fixed, so food placement is the same every run and in tests

var board: Board
var dragon: Dragon
var food := Vector2i.ZERO  # the cell the dragon eats when its head enters it
var score := 0  # how much food has been eaten
var _rng := RandomNumberGenerator.new()


func _init(grid_size: Vector2i, rng_seed: int = RNG_SEED) -> void:
	board = Board.bordered(grid_size)
	dragon = Dragon.new(grid_size)
	_rng.seed = rng_seed
	_place_food()


## One step of the rules. TODO for D4: collisions with the dragon's own body and
## with solid tiles (board.is_solid). Both need the dragon and something else,
## which is why they go here rather than in Dragon.tick.
func tick() -> void:
	dragon.tick()
	if dragon.body[0] == food:
		score += 1
		dragon.grow(GROWTH_PER_FOOD)
		_place_food()


## Put the food on a free cell: floor that no part of the dragon covers.
func _place_food() -> void:
	var free: Array[Vector2i] = []
	for cell in board.tiles:
		if not board.is_solid(cell) and cell not in dragon.body:
			free.append(cell)
	food = free[_rng.randi_range(0, free.size() - 1)]
