extends TileMap

# Initialize noise generators for different map features
# Values between -1 and 1
var moisture = FastNoiseLite.new()
var temperature = FastNoiseLite.new()
var altitude = FastNoiseLite.new()

# Dimensions of each generated chunk
var width = 32
var height = 32

# Reference to the player character
@onready var player = get_parent().get_node("Player")

# List to keep track of loaded chunks
var loaded_chunks = []
var objects = {}

var object_data = {
	
}
func _ready():
	# Set random seeds for noise variation
	moisture.seed = randi()
	temperature.seed = randi()
	altitude.seed = randi()

	# Adjust this value to change the 'smoothness' of the map; lower values mean more smooth noise
	altitude.frequency = 0.01

func _process(delta):
	# Convert the player's position to tile coordinates
	var player_tile_pos = local_to_map(player.position)

	# Generate the chunk at the player's position
	generate_chunk(player_tile_pos)

	# Unload chunks that are too far away.
	# Note: Not needed for smaller projects but if you are loading a bigger tilemap it's good practice
	unload_distant_chunks(player_tile_pos)


func generate_chunk(pos):
	for x in range(width):
		for y in range(height):
			# Generate noise values for moisture, temperature, and altitude
			var moist = moisture.get_noise_2d(pos.x - (width/2) + x, pos.y - (height/2) + y) * 10 # Values between -10 and 10
			var temp = temperature.get_noise_2d(pos.x - (width/2) + x, pos.y - (height/2) + y) * 10
			var alt = altitude.get_noise_2d(pos.x - (width/2) + x, pos.y - (height/2) + y) * 10

			# Set the cell based on altitude; adjust for different tile types
			# Need to evenly distribute -10 -> 10 to 0 -> 4....  This can be done by first adding 10
			# Gets values from 0 -> 20... Then we will multiply by 3/20 in order to remap it to 0 -> 3
			# vvv

			if alt < -4: # Arbitrary sea level value (choosing 0 will mean roughly 1/2 the world is ocean)
				set_cell(0, Vector2i(pos.x - (width/2) + x, pos.y - (height/2) + y), 0, Vector2(4, 2)) # Change x value where I've wrote three to whatever the x-coord of your oceans are
			if temp < -3.9:
				set_cell(0, Vector2i(pos.x - (width/2) + x, pos.y - (height/2) + y), 0, Vector2(5, 2)) # Change x value where I've wrote three to whatever the x-coord of your oceans are
			
			if Vector2i(pos.x, pos.y) not in loaded_chunks:
				loaded_chunks.append(Vector2i(pos.x, pos.y))

# Function to unload chunks that are too far away
func unload_distant_chunks(player_pos):
	# Set the distance threshold to at least 2 times the width to limit visual glitches
	# Higher values unload chunks further away
	var unload_distance_threshold = (width * 2) + 1

	for chunk in loaded_chunks:
		var distance_to_player = get_dist(chunk, player_pos)

		if distance_to_player > unload_distance_threshold:
			clear_chunk(chunk)
			loaded_chunks.erase(chunk)

# Function to clear a chunk
func clear_chunk(pos):
	for x in range(width):
		for y in range(height):
			set_cell(0, Vector2i(pos.x - (width/2) + x, pos.y - (height/2) + y), -1, Vector2(-1, -1), -1)

# Function to calculate distance between two points
func get_dist(p1, p2):
	var resultant = p1 - p2
	return sqrt(resultant.x ** 2 + resultant.y ** 2)

func random_tile(data, biome):
	var current_biome = data[biome]
	var rand_num = randf_range(0,2)
	var running_total = 0
	for tile in current_biome:
		running_total = running_total+current_biome[tile]
		if rand_num <= running_total:
			return tile
			
