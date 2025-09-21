extends CharacterBody3D

# === Player Settings ===
@export var speed : float = 10.0
@export var jump_velocity : float = 4.5
@export var gravity : float = 9.8
@export var mouse_sensitivity : float = 0.002

# === Look Angles ===
var yaw : float = 0.0    # left/right
var pitch : float = 0.0  # up/down

# Track snapped state
var is_snapped : bool = false
var current_prism: Node3D = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Ignore mouse input if snapped
	if is_snapped:
		# Right-click unlocks camera rotation
		if event.is_action_pressed("right_click"):
			is_snapped = false
		else:
			return

	# Handle mouse look
	if event is InputEventMouseMotion:
		yaw   -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -1.5, 1.5)

		rotation.y = yaw
		$Camera3D.rotation.x = pitch

	# Escape to unlock mouse
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Left click → snap to prism (if touching one)
	if event.is_action_pressed("left_click"):
		var prism = get_touching_prism()
		if prism:
			snap_to_prism_surface_normal(prism)

func _physics_process(delta):
	var input_dir = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	var direction = (transform.basis * input_dir).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity

	move_and_slide()

# === Detect prism collisions using slide collisions ===
func get_touching_prism() -> Node3D:
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider.is_in_group("prisms"):
			return collider
	return null

# === Snap to prism surface normal while preserving offset along the face ===
func snap_to_prism_surface_normal(prism: Node3D) -> void:
	# Get the physics engine so we can do raycasting
	var space = get_world_3d().direct_space_state
	
	# --- Step 1: Figure out which way the prism is from the player ---
	
	# Direction from the player to the center of the prism
	var direction = (prism.global_transform.origin - global_transform.origin).normalized()
	
	# Raycast is from player towards prism, this ray will contact the surface...
	# that the player is closest too
	var ray_to = global_transform.origin + direction * 2.0
	var query = PhysicsRayQueryParameters3D.new()
	query.from = global_transform.origin
	query.to = ray_to
	query.exclude = [self]

	# --- Step 2: Perform the raycast ---
	
	var result = space.intersect_ray(query)
	
	# The ray hit something – store the surface's normal (direction the surface is facing)
	if result:
		var normal: Vector3 = result.normal
		
		# Ignore vertical tilt; we only care about facing horizontally
		normal.y = 0
		normal = normal.normalized()

		# --- Step 3: Preserve the player's position along the surface ---
		
		# Vector from prism center to player
		var to_prism = global_transform.origin - prism.global_transform.origin
		
		# Project this vector onto the plane of the surface (so player stays "where they are" along the face)
		# Subtract the component that goes into/out of the surfaceicular to normal
		var parallel_offset = to_prism - normal * to_prism.dot(normal)

		# --- Step 4: Move the player slightly away from the surface ---g normal
		
		# how far we sit away from the surface
		var push_distance = 0.5
		global_position = prism.global_transform.origin + parallel_offset + normal * push_distance
		
		# Keep player's vertical position the same (don't snap up/down)
		global_position.y = global_position.y  

		# --- Step 5: Rotate the player to face the surface directly ---
		
		# Rotate player to face surface normal
		var new_basis = Basis()
		
		# -Z is forward in Godot; point it towards the surface normal
		new_basis.z = normal
		
		# up direction stays up
		new_basis.y = Vector3.UP
		
		# calculate right direction from up & forward
		new_basis.x = basis.y.cross(new_basis.z).normalized()
		
		# apply the rotation
		global_transform.basis = new_basis.orthonormalized()

		# --- Step 6: Reset the camera so it looks straight ahead ---
		$Camera3D.rotation = Vector3.ZERO

		# --- Step 7: Lock camera rotation to force facing direction ---
		is_snapped = true
		print("Snapped to prism surface normal with preserved offset:", normal)
