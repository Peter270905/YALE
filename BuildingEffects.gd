extends Node
class_name BuildingEffects

# ← Эффект постройки — зелёные искры
static func play_place_effect(position: Vector3, parent: Node):
	var particles = GPUParticles3D.new()
	parent.add_child(particles)
	particles.global_position = position
	
	var material = ParticleProcessMaterial.new()
	
	# Форма выброса — сфера
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.3
	
	# Направление — вверх с разбросом
	material.direction = Vector3(0, 1, 0)
	material.spread = 60.0
	material.initial_velocity_min = 1.5
	material.initial_velocity_max = 3.0
	
	# Гравитация
	material.gravity = Vector3(0, -4.0, 0)
	
	# Размер
	material.scale_min = 0.05
	material.scale_max = 0.12
	
	# Цвет — зелёный → жёлтый → прозрачный
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.4, 1.0, 0.3, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 0.2, 0.0))
	var gradient_tex = GradientTexture1D.new()
	gradient_tex.gradient = gradient
	material.color_ramp = gradient_tex
	
	particles.process_material = material
	
	# Меш — маленький шарик
	var mesh = SphereMesh.new()
	mesh.radius = 0.04
	mesh.height = 0.08
	particles.draw_pass_1 = mesh
	
	particles.amount = 24
	particles.lifetime = 0.6
	particles.explosiveness = 0.9  # все частицы сразу
	particles.one_shot = true
	particles.emitting = true
	
	# Удаляем после завершения
	var timer = particles.get_tree().create_timer(1.2)
	timer.timeout.connect(func(): 
		if is_instance_valid(particles):
			particles.queue_free()
	)

# ← Эффект сноса — серая пыль и щепки
static func play_demolish_effect(position: Vector3, parent: Node):
	# Пыль
	var dust = GPUParticles3D.new()
	parent.add_child(dust)
	dust.global_position = position
	
	var dust_mat = ParticleProcessMaterial.new()
	dust_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	dust_mat.emission_box_extents = Vector3(0.5, 0.3, 0.5)
	dust_mat.direction = Vector3(0, 1, 0)
	dust_mat.spread = 80.0
	dust_mat.initial_velocity_min = 0.5
	dust_mat.initial_velocity_max = 2.0
	dust_mat.gravity = Vector3(0, -1.0, 0)
	dust_mat.scale_min = 0.1
	dust_mat.scale_max = 0.35
	
	# Цвет — серый → прозрачный
	var dust_gradient = Gradient.new()
	dust_gradient.set_color(0, Color(0.7, 0.65, 0.6, 0.8))
	dust_gradient.set_color(1, Color(0.5, 0.45, 0.4, 0.0))
	var dust_tex = GradientTexture1D.new()
	dust_tex.gradient = dust_gradient
	dust_mat.color_ramp = dust_tex
	
	dust.process_material = dust_mat
	
	var dust_mesh = SphereMesh.new()
	dust_mesh.radius = 0.08
	dust_mesh.height = 0.16
	dust.draw_pass_1 = dust_mesh
	
	dust.amount = 20
	dust.lifetime = 1.0
	dust.explosiveness = 0.8
	dust.one_shot = true
	dust.emitting = true
	
	# Обломки — коричневые кубики
	var debris = GPUParticles3D.new()
	parent.add_child(debris)
	debris.global_position = position
	
	var debris_mat = ParticleProcessMaterial.new()
	debris_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	debris_mat.emission_sphere_radius = 0.2
	debris_mat.direction = Vector3(0, 1, 0)
	debris_mat.spread = 90.0
	debris_mat.initial_velocity_min = 2.0
	debris_mat.initial_velocity_max = 5.0
	debris_mat.gravity = Vector3(0, -9.8, 0)
	debris_mat.scale_min = 0.04
	debris_mat.scale_max = 0.1
	
	# Вращение обломков
	debris_mat.angular_velocity_min = -180.0
	debris_mat.angular_velocity_max = 180.0
	
	var debris_gradient = Gradient.new()
	debris_gradient.set_color(0, Color(0.6, 0.4, 0.2, 1.0))
	debris_gradient.set_color(1, Color(0.4, 0.25, 0.1, 1.0))
	var debris_tex = GradientTexture1D.new()
	debris_tex.gradient = debris_gradient
	debris_mat.color_ramp = debris_tex
	
	debris.process_material = debris_mat
	
	var debris_mesh = BoxMesh.new()
	debris_mesh.size = Vector3(0.08, 0.08, 0.08)
	debris.draw_pass_1 = debris_mesh
	
	debris.amount = 12
	debris.lifetime = 0.8
	debris.explosiveness = 1.0
	debris.one_shot = true
	debris.emitting = true
	
	# Удаляем оба эффекта после завершения
	var timer = dust.get_tree().create_timer(1.5)
	timer.timeout.connect(func():
		if is_instance_valid(dust):
			dust.queue_free()
		if is_instance_valid(debris):
			debris.queue_free()
	)
