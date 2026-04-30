extends Panel

var current_instruction = "---"
var current_result = 0
var alu_op = "---"

func _ready():
	setup_display()

func setup_display():
	for child in get_children():
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "PIPELINE STATUS"
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	# Current instruction
	var instr_row = HBoxContainer.new()
	var instr_label = Label.new()
	instr_label.text = "Current: "
	instr_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	current_instruction = Label.new()
	current_instruction.text = "---"
	current_instruction.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	instr_row.add_child(instr_label)
	instr_row.add_child(current_instruction)
	vbox.add_child(instr_row)
	
	# ALU result
	var alu_row = HBoxContainer.new()
	var alu_label = Label.new()
	alu_label.text = "ALU Result: "
	alu_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	var alu_result = Label.new()
	alu_result.text = "0"
	alu_result.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	alu_result.name = "result"
	var alu_op_label = Label.new()
	alu_op_label.text = " Op: "
	alu_op_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	var alu_op_val = Label.new()
	alu_op_val.text = "---"
	alu_op_val.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	alu_op_val.name = "op"
	
	alu_row.add_child(alu_label)
	alu_row.add_child(alu_result)
	alu_row.add_child(alu_op_label)
	alu_row.add_child(alu_op_val)
	vbox.add_child(alu_row)
	
	# Store references
	current_instruction = current_instruction
	alu_result = alu_result
	alu_op_val = alu_op_val
	
	# State registers section
	var state_title = Label.new()
	state_title.text = "State Registers"
	state_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	vbox.add_child(state_title)
	
	var state_grid = GridContainer.new()
	state_grid.columns = 2
	state_grid.add_theme_constant_override("h_separation", 20)
	
	var state_regs = ["IF/ID:", "ID/EX:", "EX/MEM:", "MEM/WB:"]
	for sr in state_regs:
		var name_lbl = Label.new()
		name_lbl.text = sr
		name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		var val_lbl = Label.new()
		val_lbl.text = "empty"
		val_lbl.add_theme_color_override("font_color", Color.WHITE)
		val_lbl.name = sr.replace("/", "_")
		state_grid.add_child(name_lbl)
		state_grid.add_child(val_lbl)
	
	vbox.add_child(state_grid)

func update_instruction(instr: String):
	if current_instruction:
		current_instruction.text = instr

func update_alu(result: int, op: String):
	var alu_result = find_child("result")
	var alu_op = find_child("op")
	if alu_result:
		alu_result.text = str(result)
	if alu_op:
		alu_op.text = op

func update_state_register(reg: String, value: String):
	var label = find_child(reg.replace("/", "_"))
	if label:
		if value.length() > 25:
			value = value.substr(0, 22) + "..."
		label.text = value

func reset():
	if current_instruction:
		current_instruction.text = "---"
	var alu_result = find_child("result")
	var alu_op = find_child("op")
	if alu_result:
		alu_result.text = "0"
	if alu_op:
		alu_op.text = "---"
	
	var state_regs = ["IF/ID_", "ID/EX_", "EX/MEM_", "MEM/WB_"]
	for sr in state_regs:
		var label = find_child(sr)
		if label:
			label.text = "empty"
