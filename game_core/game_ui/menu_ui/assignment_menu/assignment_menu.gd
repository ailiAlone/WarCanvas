extends VBoxContainer
class_name AssignmentMenu

# 引用场景节点
@onready var items_container = $ItemsContainer

# 引用assignment_item场景
var assignment_item_scene = preload("res://game_core/game_ui/menu_ui/assignment_menu/assignment_item/assignment_item.tscn")

func _ready() -> void:
	RecipeData.ensure_recipes_loaded()
	for recipe_template in RecipeData.get_all_recipes():
			var assignment_item = assignment_item_scene.instantiate()
			assignment_item.name = str(items_container.get_child_count()).validate_node_name()
			# 设置物品数据
			assignment_item.set_recipe_template(recipe_template)
			# 将所有物品添加到同一个容器
			items_container.add_child(assignment_item)
	
# 更新关联的生产系统
func set_headquarter(headquarter: Headquarter):
	# 更新物品数量和分配状态
	for assignment_item in items_container.get_children():
		if assignment_item is AssignmentItem:
			assignment_item.update_assignment_item_data(headquarter.production.get_production_line_by_id(assignment_item.name.to_int()),headquarter)
	
func update():
	# 更新UI
	for assignment_item in items_container.get_children():
		if assignment_item is AssignmentItem:
			assignment_item.update()
