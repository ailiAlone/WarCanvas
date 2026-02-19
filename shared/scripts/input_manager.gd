extends Node

# 信号定义
signal key_w_pressed(pressed: bool)
signal key_a_pressed(pressed: bool)
signal key_s_pressed(pressed: bool)
signal key_d_pressed(pressed: bool)
signal key_n_pressed(pressed: bool)
signal key_q_pressed(pressed: bool)
signal key_e_pressed(pressed: bool)
signal key_escape_pressed(pressed: bool)
signal mouse_left_pressed(pressed: bool)
signal mouse_right_pressed(pressed: bool)
signal mouse_wheel(direction: int)  # 1 = 上滚, -1 = 下滚
signal mouse_moved(position: Vector2, delta: Vector2)

var input_enabled = true

func _ready():
	# 设置处理优先级
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	# 处理键盘输入
	if event is InputEventKey:
		match event.keycode:
			KEY_W:
				key_w_pressed.emit(event.pressed)
			KEY_A:
				key_a_pressed.emit(event.pressed)
			KEY_S:
				key_s_pressed.emit(event.pressed)
			KEY_D:
				key_d_pressed.emit(event.pressed)
			KEY_N:
				key_n_pressed.emit(event.pressed)
			KEY_Q:
				key_q_pressed.emit(event.pressed)
			KEY_E:
				key_e_pressed.emit(event.pressed)
			KEY_ESCAPE:
				key_escape_pressed.emit(event.pressed)
	
	# 处理鼠标输入
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				mouse_left_pressed.emit(event.pressed)
			MOUSE_BUTTON_RIGHT:
				mouse_right_pressed.emit(event.pressed)
			MOUSE_BUTTON_WHEEL_UP:
				mouse_wheel.emit(1)
			MOUSE_BUTTON_WHEEL_DOWN:
				mouse_wheel.emit(-1)
	
	# 处理鼠标移动
	elif event is InputEventMouseMotion:
		mouse_moved.emit(event.position, event.relative)
