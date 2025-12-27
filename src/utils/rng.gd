class_name RNG
extends RefCounted

# Seedable random number generator wrapper for testing

static var _instance: RandomNumberGenerator = null

static func get_instance() -> RandomNumberGenerator:
	if _instance == null:
		_instance = RandomNumberGenerator.new()
		_instance.randomize()
	return _instance

static func set_seed(seed_value: int) -> void:
	get_instance().seed = seed_value

static func randomize_seed() -> void:
	get_instance().randomize()

static func randf() -> float:
	return get_instance().randf()

static func randf_range(from: float, to: float) -> float:
	return get_instance().randf_range(from, to)

static func randi() -> int:
	return get_instance().randi()

static func randi_range(from: int, to: int) -> int:
	return get_instance().randi_range(from, to)

static func randfn(mean: float = 0.0, deviation: float = 1.0) -> float:
	return get_instance().randfn(mean, deviation)
