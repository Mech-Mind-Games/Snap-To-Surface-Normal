extends Area3D

# Reference to the player (drag your player into this in Inspector)
@export var player : CharacterBody3D

func _on_body_entered(body):
	if body == player:
		align_player_to_cube(body)

func align_player_to_cube(body: CharacterBody3D):
	var cube = get_parent() # StaticBody3D (the prism)
	var cube_transform = cube.global_transform
	var cube_extents = cube.get_node("CollisionShape3D").shape.extents

	# Vector from cube center to player
	var to_player = body.global_transform.origin - cube_transform.origin

	# Find closest axis (±X, ±Y, ±Z)
	var axes = {
		Vector3.RIGHT:  abs(to_player.x) - cube_extents.x,
		-Vector3.RIGHT: abs(to_player.x) - cube_extents.x,
		Vector3.UP:     abs(to_player.y) - cube_extents.y,
		-Vector3.UP:    abs(to_player.y) - cube_extents.y,
		Vector3.FORWARD:abs(to_player.z) - cube_extents.z,
		-Vector3.FORWARD:abs(to_player.z) - cube_extents.z,
	}

	var closest_normal = Vector3.ZERO
	var min_dist = INF
	for normal in axes.keys():
		if axes[normal] < min_dist:
			min_dist = axes[normal]
			closest_normal = normal

	# Rotate the player so its forward matches this normal
	var new_basis = Basis()
	new_basis.z = -closest_normal # look forward along normal
	new_basis.y = Vector3.UP      # keep "up" world up
	new_basis.x = new_basis.y.cross(new_basis.z).normalized()
	new_basis = Basis(new_basis.x, new_basis.y, new_basis.z).orthonormalized()

	body.global_transform.basis = new_basis

	# Reset camera rotation too
	var cam = body.get_node("Camera3D")
	cam.rotation = Vector3.ZERO
