extends VBoxContainer
class_name ExpeditionItem

# UI元素引用
@onready var texture_rect: TextureRect = $HBoxContainer/TextureRect
@onready var quantity_label: Label = $HBoxContainer/VBoxContainer/Label2
@onready var quantity_spinbox: SpinBox = $SpinBox

# 物品模板
var _item_template: ItemData.ItemTemplate = null

# 最大数量限制
var max_quantity: int = 99

func _ready():
	# 设置数量输入框的范围
	quantity_spinbox.max_value = max_quantity
	quantity_spinbox.min_value = 0
	quantity_spinbox.value = 0
	
# 设置物品模板
func set_item_template(item_template: ItemData.ItemTemplate):
	_item_template = item_template
	
	# 设置物品图标
	if item_template.icon:
		texture_rect.texture = item_template.icon
	else:
		push_warning("物品图标为空: " + item_template.name)
	
	# 设置工具提示
	texture_rect.tooltip_text = item_template.name

# 更新可用数量
func update_available_quantity(inventory: ItemStock):
	if not _item_template:
		return
	
	var available_quantity = inventory.get_item_quantity(_item_template.id)
	quantity_spinbox.max_value = min(available_quantity, max_quantity)
	
	# 更新库存显示
	quantity_label.text = str(available_quantity)
	
	# 如果当前选择的数量超过可用数量，则调整为最大可用数量
	if quantity_spinbox.value > quantity_spinbox.max_value:
		quantity_spinbox.value = quantity_spinbox.max_value

# 获取物品ID
func get_item_id() -> String:
	return _item_template.id if _item_template else ""

# 获取物品模板
func get_item_template() -> ItemData.ItemTemplate:
	return _item_template

# 获取当前选择数量
func get_quantity() -> int:
	return quantity_spinbox.value as int

# 设置数量
func set_quantity(value: int):
	quantity_spinbox.value = clamp(value, 0, max_quantity)
