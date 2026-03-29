extends Area3D

@export var sanity_drain_rate: float = 10.0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		var player_state = body.get_node_or_null("state")
		if player_state:
			player_state.enter_sanity_drain_area(sanity_drain_rate)

func _on_body_exited(body: Node):
	if body.is_in_group("player"):
		var player_state = body.get_node_or_null("state")
		if player_state:
			player_state.exit_sanity_drain_area()
