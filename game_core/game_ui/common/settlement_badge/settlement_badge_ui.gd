extends PanelContainer
class_name SettlementBadgeUI
@onready var name_label = $MarginContainer/VBoxContainer/Name
@onready var population_label = $MarginContainer/VBoxContainer/TotalPopulation

func set_name_label(text: String):
	name_label.text = text

func set_population_label(text: String):
	population_label.text = text
