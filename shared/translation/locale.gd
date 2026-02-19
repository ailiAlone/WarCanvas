extends Node
# 存储翻译数据的字典
var translations: Dictionary = {}

# 当前语言
var current_language: String = "zh"

func _init():
	# 加载翻译数据
	load_translations()

# 从CSV文件加载翻译数据
func load_translations() -> void:
	var file_path = "res://shared/translation/translation.csv"
	if not FileAccess.file_exists(file_path):
		push_error("翻译文件不存在: " + file_path)
		return
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		push_error("无法打开翻译文件: " + file_path)
		return
	
	# 查找标题行
	var header_line = ""
	var headers = []
	
	# 逐行读取，直到找到标题行
	while not file.eof_reached():
		var line = file.get_line()
		if line.strip_edges().is_empty():
			continue
			
		var parts = line.split(",")
		# 检查是否包含key, en, zh列
		var has_key = false
		var has_en = false
		var has_zh = false
		
		for part in parts:
			var header = part.strip_edges().to_lower()
			if header == "key":
				has_key = true
			elif header == "en":
				has_en = true
			elif header == "zh":
				has_zh = true
		
		if has_key and has_en and has_zh:
			header_line = line
			headers = parts
			break
	
	if headers.is_empty():
		push_error("翻译文件格式错误，找不到标题行: key, en, zh")
		file.close()
		return
	
	# 查找语言列的索引
	var key_index = -1
	var en_index = -1
	var zh_index = -1
	
	for i in range(headers.size()):
		var header = headers[i].strip_edges().to_lower()
		if header == "key":
			key_index = i
		elif header == "en":
			en_index = i
		elif header == "zh":
			zh_index = i
	
	# 验证是否找到了所有必要的列
	if key_index == -1 or en_index == -1 or zh_index == -1:
		push_error("翻译文件格式错误，缺少必要的列: key, en, zh")
		file.close()
		return
	
	# 读取每一行数据
	while not file.eof_reached():
		var line = file.get_line()
		if line.strip_edges().is_empty():
			continue
			
		var parts = line.split(",")
		if parts.size() >= max(key_index, en_index, zh_index) + 1:
			var key = parts[key_index].strip_edges()
			var en_text = parts[en_index].strip_edges()
			var zh_text = parts[zh_index].strip_edges()
			
			if not key.is_empty():
				translations[key] = {
					"en": en_text,
					"zh": zh_text
				}
	
	file.close()

# 设置当前语言
func set_language(language: String) -> void:
	if language in ["en", "zh"]:
		current_language = language
	else:
		push_error("unsupport language")

# 获取当前语言
func get_language() -> String:
	return current_language

# 根据键获取翻译文本
func get_text(key: String) -> String:
	if translations.has(key):
		return translations[key][current_language]
	
	# 如果找不到翻译，返回键本身
	return key

# 获取所有可用的翻译键
func get_all_keys() -> Array:
	return translations.keys()

# 检查是否存在某个键的翻译
func has_translation(key: String) -> bool:
	return translations.has(key)
