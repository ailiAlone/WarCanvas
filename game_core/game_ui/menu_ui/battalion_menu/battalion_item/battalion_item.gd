extends VBoxContainer
class_name BattalionItem

@onready var texture_button: TextureButton = $TextureButton
@onready var inventory_label: Label = $HBoxContainer/InventoryLabel

var _item_template: ItemData.ItemTemplate = null

func set_item_template(item_template: ItemData.ItemTemplate):
	_item_template = item_template
	if item_template == null:
		# $TextureButton.texture_normal = Texture.new()
		$HBoxContainer/NameLabel.text = "无"
		$HBoxContainer/InventoryLabel.text = ""
	else:
		$TextureButton.texture_normal = item_template.icon
		$HBoxContainer/NameLabel.text = item_template.name
		$HBoxContainer/InventoryLabel.text = str(0)

func update_item_inventory(inventory: int):
	if _item_template != null:
		inventory_label.text = str(inventory)
