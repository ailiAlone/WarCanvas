extends PanelContainer
class_name BuildingBadgeUI
@onready var label = $MarginContainer/Label

func set_text(text: String):
	label.text = text