extends RigidBody3D

@export var slot_data: SlotData
@export var pickup_delay := 1.0
var can_be_picked_up := false
@export var item_data: ItemData
@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var area_3d: Area3D = $Area3D

func _ready() -> void:
	sprite_3d.texture = slot_data.item_data.texture
	_disable_pickup_temporarily()
	#spawn_quality_particles()

func _disable_pickup_temporarily() -> void:
	can_be_picked_up = false
	sprite_3d.modulate = Color(1, 1, 1, 0.5)
	await get_tree().create_timer(pickup_delay).timeout
	can_be_picked_up = true
	sprite_3d.modulate = Color(1, 1, 1, 1)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not can_be_picked_up:
		return

	if body.has_node("state") and body.state.inventory_data.pick_up_slot_data(slot_data):
		queue_free()


#func spawn_quality_particles():
	#
	#if !slot_data or !slot_data.item_data:
		#return
	#
	#var quality = slot_data.item_data.quality
	#
	#if slot_data.item_data.quality_colors.has(quality):
		#var particle_color = slot_data.item_data.quality_colors[quality]
		#if $CollisionShape3D/GPUParticles3D.draw_pass_1:
			#var material = $CollisionShape3D/GPUParticles3D.draw_pass_1.surface_get_material(0)
			#if material:
				#material.albedo_color = particle_color
