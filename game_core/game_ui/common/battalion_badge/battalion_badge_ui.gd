extends PanelContainer
class_name BattalionBadgeUI
@onready var name_label = $MarginContainer/VBoxContainer/Name
@onready var strength_label = $MarginContainer/VBoxContainer/TotalStrength

func set_name_label(text: String):
	name_label.text = text

func set_strength_label(text: String):
	strength_label.text = text
