# SkillBar.gd
# A bottom-center UI bar showing all equipped skills + basic attack.
# Slots are drawn as simple rounded-corner squares.
# Empty slots appear dimmed/greyed; filled slots show the skill texture.
extends Control

# -- Slot visuals -------------------------------------------------------------
var _slot_size: float = 44.0
var _slot_gap: float = 6.0

# -- Colors -------------------------------------------------------------------
var _empty_slot_color: Color = Color(0.2, 0.2, 0.2, 0.5)
var _filled_slot_bg: Color = Color(0.15, 0.15, 0.15, 0.7)
var _basic_attack_tint: Color = Color(0.8, 0.8, 0.8, 0.9)
var _slot_border_color: Color = Color(0.4, 0.4, 0.4, 0.6)

# -- Cached style boxes -------------------------------------------------------
var _empty_style: StyleBoxFlat
var _filled_style: StyleBoxFlat

# -- Number of slots (1 basic attack + up to 4 skills) ------------------------
const TOTAL_SLOTS: int = 5
const BASIC_ATTACK_SLOT: int = 0


# -- Lifecycle ----------------------------------------------------------------
func _ready() -> void:
	_build_styles()
	
	# React to skill changes
	PlayerData.skill_added.connect(_on_skill_added)
	
	custom_minimum_size = Vector2(TOTAL_SLOTS * _slot_size + (TOTAL_SLOTS - 1) * _slot_gap, _slot_size + 12)
	
	# Draw initial state
	queue_redraw()


func _exit_tree() -> void:
	if PlayerData.skill_added.is_connected(_on_skill_added):
		PlayerData.skill_added.disconnect(_on_skill_added)


# -- Style setup --------------------------------------------------------------
func _build_styles() -> void:
	_empty_style = StyleBoxFlat.new()
	_empty_style.bg_color = _empty_slot_color
	_empty_style.border_color = _slot_border_color
	_empty_style.border_width_left = 1
	_empty_style.border_width_right = 1
	_empty_style.border_width_top = 1
	_empty_style.border_width_bottom = 1
	_empty_style.corner_radius_top_left = 6
	_empty_style.corner_radius_top_right = 6
	_empty_style.corner_radius_bottom_left = 6
	_empty_style.corner_radius_bottom_right = 6
	
	_filled_style = StyleBoxFlat.new()
	_filled_style.bg_color = _filled_slot_bg
	_filled_style.border_color = Color(0.6, 0.6, 0.6, 0.8)
	_filled_style.border_width_left = 1
	_filled_style.border_width_right = 1
	_filled_style.border_width_top = 1
	_filled_style.border_width_bottom = 1
	_filled_style.corner_radius_top_left = 6
	_filled_style.corner_radius_top_right = 6
	_filled_style.corner_radius_bottom_left = 6
	_filled_style.corner_radius_bottom_right = 6


# -- Events -------------------------------------------------------------------
func _on_skill_added(_slot_index: int, _skill: Resource) -> void:
	queue_redraw()


# -- Drawing ------------------------------------------------------------------
func _draw() -> void:
	var total_width = TOTAL_SLOTS * _slot_size + (TOTAL_SLOTS - 1) * _slot_gap
	var start_x = (size.x - total_width) / 2.0
	var y = (size.y - _slot_size) / 2.0
	
	var skills = PlayerData.current_skills
	
	for i in range(TOTAL_SLOTS):
		var x = start_x + i * (_slot_size + _slot_gap)
		var slot_rect = Rect2(x, y, _slot_size, _slot_size)
		
		if i == BASIC_ATTACK_SLOT:
			# Basic attack slot — always filled
			_draw_slot(slot_rect, null, true)
		else:
			var skill_idx = i - 1  # skills start after basic attack
			var has_skill = skill_idx < skills.size() and skills[skill_idx] != null
			var skill_res = skills[skill_idx] if has_skill else null
			_draw_slot(slot_rect, skill_res, has_skill)


func _draw_slot(rect: Rect2, skill_res: Skill, filled: bool) -> void:
	if filled:
		draw_style_box(_filled_style, rect)
		
		if skill_res and skill_res.texture:
			# Center the texture in the slot with a small margin
			var margin = 4.0
			var tex_rect = Rect2(
				rect.position.x + margin,
				rect.position.y + margin,
				rect.size.x - margin * 2,
				rect.size.y - margin * 2
			)
			draw_texture_rect(skill_res.texture, tex_rect, false, Color.WHITE)
		else:
			# Basic attack placeholder — draw a simple sword-like indicator
			var center = rect.get_center()
			var r = rect.size.x * 0.25
			# Draw a small circle as placeholder
			draw_circle(center, r, _basic_attack_tint)
	else:
		draw_style_box(_empty_style, rect)
