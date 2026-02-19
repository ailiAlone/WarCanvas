# 环形链表
class_name CircularLinkedList

# 节点类
class CircularLinkedListNode:
	var data
	var next: CircularLinkedListNode = null
	var prev: CircularLinkedListNode = null
	
	func _init(_data):
		data = _data

var _current: CircularLinkedListNode = null
var _tail: CircularLinkedListNode = null  # 添加尾节点标志
var _size: int = 0

# 添加节点到尾部的正确实现
func append(data):
	var new_node = CircularLinkedListNode.new(data)
	_size += 1
	
	if not _current:
		# 第一个节点，指向自己形成环
		_current = new_node
		_tail = new_node
		new_node.next = new_node
		new_node.prev = new_node
	else:
		# 插入到尾节点之后（也就是头节点之前）
		var head = _tail.next  # 头节点是尾节点的下一个
		
		# 连接新节点
		new_node.prev = _tail
		new_node.next = head
		
		# 更新相邻节点的引用
		_tail.next = new_node
		head.prev = new_node
		
		# 更新尾节点
		_tail = new_node

# 删除当前节点
func remove_current():
	if not _current:
		return null
	
	_size -= 1
	var data = _current.data
	var is_tail = (_current == _tail)  # 检查是否是尾节点
	
	if _size == 0:
		# 最后一个节点
		_current = null
		_tail = null
	else:
		var prev_node = _current.prev
		var next_node = _current.next
		prev_node.next = next_node
		next_node.prev = prev_node
		_current = next_node  # 移动到下一个
		
		if is_tail:
			_tail = prev_node  # 更新尾节点指向前一个
	
	return data

# 删除指定节点
func remove_node(node: CircularLinkedListNode):
	if not node:
		return null
	
	var is_current = (node == _current)
	var is_tail = (node == _tail)  # 检查是否是尾节点
	var data = node.data
	
	if _size == 1:
		_current = null
		_tail = null
	else:
		var prev_node = node.prev
		var next_node = node.next
		prev_node.next = next_node
		next_node.prev = prev_node
		
		if is_current:
			_current = next_node
		
		if is_tail:
			_tail = prev_node  # 更新尾节点指向前一个
	
	_size -= 1
	return data

# 移动到下一个
func next():
	if not _current:
		return null
	_current = _current.next
	return _current.data

# 移动到上一个
func prev():
	if not _current:
		return null
	_current = _current.prev
	return _current.data

# 获取当前节点数据
func current():
	return _current.data if _current else null

# 获取尾节点数据
func tail():
	return _tail.data if _tail else null

# 获取尾节点
func tail_node():
	return _tail

# 查找节点
func find(data):
	if not _current:
		return null
	
	var node = _current
	for i in range(_size):
		if node.data == data:
			return node
		node = node.next
	return null

# 删除指定数据的节点
func remove(data):
	var node = find(data)
	if node:
		return remove_node(node)
	return null

# 获取大小
func size() -> int:
	return _size

# 是否为空
func is_empty() -> bool:
	return _size == 0

# 转换为数组（从当前节点开始）
func to_array():
	if not _current:
		return []
	
	var result = []
	var node = _current
	for i in range(_size):
		result.append(node.data)
		node = node.next
	return result

# 转换为数组（从头节点开始）
func to_array_from_head():
	if not _current:
		return []
	
	var result = []
	var node = _current
	# 先找到头节点（当前节点的前一个）
	while node.next != _current:
		node = node.next
	
	# 从头节点开始遍历
	for i in range(_size):
		result.append(node.data)
		node = node.next
	return result
