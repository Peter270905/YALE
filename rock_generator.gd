@tool
extends MeshInstance3D
class_name RockGenerator

@export var generate := false:
	set(value):
		if value:
			generate_rock()
		generate = false

@export_range(0.1, 1.0) var roughness := 0.35:
	set(value):
		roughness = value
		if Engine.is_editor_hint():
			generate_rock()

@export_range(0.5, 20) var size := 1.0:
	set(value):
		size = value
		if Engine.is_editor_hint():
			generate_rock()

@export_range(2, 12) var resolution := 4:
	set(value):
		resolution = value
		if Engine.is_editor_hint():
			generate_rock()

@export var flatten_bottom := true:
	set(value):
		flatten_bottom = value
		if Engine.is_editor_hint():
			generate_rock()

@export var rock_seed := 0:
	set(value):
		rock_seed = value
		if Engine.is_editor_hint():
			generate_rock()

@export var create_collision := true

var noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()

func _ready():
	generate_rock()
	
	
	
func generate_rock():
	if not is_inside_tree():
		return
	
	if rock_seed == 0:
		rng.randomize()
		rock_seed = rng.randi()
	else:
		rng.seed = rock_seed
	
	noise.seed = rock_seed
	noise.frequency = 1.2
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.5
	noise.fractal_lacunarity = 2.2
	
	detail_noise.seed = rock_seed + 1
	detail_noise.frequency = 4.0
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	# BASE SHAPE
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 12 + resolution * 8
	sphere.rings = 8 + resolution * 6
	
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.create_from(sphere, 0)
	var tmp = st.commit()
	
	var arrays = tmp.surface_get_arrays(0)
	var verts = arrays[Mesh.ARRAY_VERTEX]
	var indices = arrays[Mesh.ARRAY_INDEX]
	
	var is_tall = rng.randf() > 0.5
	
	var squash_x = rng.randf_range(0.75, 1.2)
	var squash_y: float
	var squash_z = rng.randf_range(0.75, 1.2)
	
	if is_tall:
		squash_y = rng.randf_range(1.0, 1.6)
	else:
		squash_y = rng.randf_range(0.4, 0.7)
	
	# DEFORM
	for i in verts.size():
		var v: Vector3 = verts[i]
		
		v.x *= squash_x
		v.y *= squash_y
		v.z *= squash_z
		
		var dir = v.normalized()
		var dist = v.length()
		
		var world_pos = v * 2.0
		var n1 = noise.get_noise_3d(world_pos.x, world_pos.y, world_pos.z)
		
		n1 = smoothstep(-1.0, 1.0, n1) * 2.0 - 1.0
		
		var n2 = detail_noise.get_noise_3d(world_pos.x * 2.5, world_pos.y * 2.5, world_pos.z * 2.5)
		
		var displacement = n1 * roughness * 0.4 + n2 * roughness * 0.1
		
		v = dir * (dist + displacement)
		
		var bump = noise.get_noise_3d(world_pos.x * 0.5, world_pos.y * 0.5, world_pos.z * 0.5)
		if bump > 0.3:
			v += dir * bump * roughness * 0.2
		
		if flatten_bottom:
			var bottom_threshold = -0.2 * squash_y
			if v.y < bottom_threshold:
				var flatten_amount = smoothstep(bottom_threshold, bottom_threshold - 0.2, v.y)
				var target_y = bottom_threshold - 0.1
				v.y = lerp(v.y, target_y, flatten_amount * 0.85)
				var expand = 1.0 + flatten_amount * 0.1
				v.x *= expand
				v.z *= expand
		
		verts[i] = v
	
	# BUILD
	st.clear()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(0, indices.size(), 3):
		st.add_vertex(verts[indices[i]])
		st.add_vertex(verts[indices[i+1]])
		st.add_vertex(verts[indices[i+2]])
	
	st.generate_normals()
	st.index()
	
	mesh = st.commit()
	scale = Vector3.ONE * size
	
	if create_collision:
		call_deferred("_create_collision_deferred", verts)

func _create_collision_deferred(verts: PackedVector3Array):
	var parent = get_parent()
	if not parent or not parent is StaticBody3D:
		return
	
	for child in parent.get_children():
		if child is CollisionShape3D and child != self:
			child.queue_free()
	
	var scaled_verts = PackedVector3Array()
	for v in verts:
		scaled_verts.append(v * size)
	
	var collision_shape = CollisionShape3D.new()
	var convex = ConvexPolygonShape3D.new()
	convex.points = scaled_verts
	collision_shape.shape = convex
	
	parent.add_child(collision_shape)
	
	if Engine.is_editor_hint():
		collision_shape.owner = get_tree().edited_scene_root
	
