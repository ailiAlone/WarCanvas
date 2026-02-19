class_name Battalion
extends Node

var unit: Unit = null
var basic_info_window: Node3D

var target:Dictionary = {
	"type":"",			# 目标类型（ATTACK、DEFEND）
	"headquarter":null
}

# 所属 headquarter
var headquarter: Headquarter = null

func _init(p_info:UnitData.UnitInfo,p_headquarter:Headquarter,grid:Grid):
	headquarter = p_headquarter
	unit = Unit.new(p_info,grid,self)
	add_child(unit)
