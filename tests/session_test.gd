extends "res://tests/test_case.gd"


func test_a_tick_moves_the_dragon_head() -> void:
	var session := Session.new(Vector2i(10, 10))
	session.tick()
	assert_eq(session.dragon.body[0], Vector2i(6, 5))


func test_the_dragon_starts_on_open_floor_inside_a_wall() -> void:
	var session := Session.new(Vector2i(10, 10))
	assert_true(session.board.is_solid(Vector2i(0, 0)))
	assert_true(not session.board.is_solid(session.dragon.body[0]))


func test_eating_grows_the_body_by_the_chosen_amount() -> void:
	var session := Session.new(Vector2i(10, 10))
	var start := session.dragon.body.size()
	session.food = session.dragon.body[0] + session.dragon.heading  # straight ahead
	session.tick()  # the head enters the food and eats it
	session.food = Vector2i(-1, -1)  # park the new food off the board: nothing to eat
	session.tick()  # the bite keeps this tick's tail, so the body is longer now
	assert_eq(session.dragon.body.size(), start + Session.GROWTH_PER_FOOD)


func test_new_food_never_appears_on_the_body() -> void:
	for rng_seed in 20:  # each seed respawns the food somewhere different
		var session := Session.new(Vector2i(10, 10), rng_seed)
		session.food = session.dragon.body[0] + session.dragon.heading
		session.tick()  # the head enters the food: it is eaten, and new food is placed
		assert_true(not session.board.is_solid(session.food))
		assert_true(session.food not in session.dragon.body)


func test_the_score_counts_what_was_eaten() -> void:
	var session := Session.new(Vector2i(10, 10))
	session.food = session.dragon.body[0] + session.dragon.heading
	session.tick()
	session.food = session.dragon.body[0] + session.dragon.heading
	session.tick()
	assert_eq(session.score, 2)
