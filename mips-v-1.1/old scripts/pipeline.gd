extends Panel

# Store instructions in each pipeline stage
var if_instr = "---"
var id_instr = "---"  
var ex_instr = "---"
var mem_instr = "---"
var wb_instr = "---"

# State registers (what's passed between stages)
var if_id_reg = "---"
var id_ex_reg = "---"
var ex_mem_reg = "---"
var mem_wb_reg = "---"

# ALU info
var alu_result = 0
var alu_operation = "---"

# UI Labels
var if_label: Label
var id_label: Label
var ex_label: Label
var mem_label: Label
var wb_label: Label

var if_id_label: Label
var id_ex_label: Label
var ex_mem_label: Label
var mem_wb_label: Label

var alu_result_label: Label
var alu_op_label: Label
var current_instr_label: Label
var pc_display_label: Label
var state_pc_labels = {
	"IF/ID": null,
	"ID/EX": null,
	"EX/MEM": null,
	"MEM/WB": null
}
var state_instr_labels = {
	"IF/ID": null,
	"ID/EX": null,
	"EX/MEM": null,
	"MEM/WB": null
}

func _ready():
	create_ui()

func create_ui():
	# Clear old
	for child in get_children():
		child.queue_free()
	
	var main = VBoxContainer.new()
	add_child(main)
	
	# Title
	var title = Label.new()
	title.text = "5-STAGE PIPELINE"
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 16)
	main.add_child(title)
	
	# Current instruction
	var current_row = HBoxContainer.new()
	current_row.add_child(create_label("Current: ", Color(0.7,0.7,0.7)))
	current_instr_label = create_label("---", Color(0.3,0.8,1.0))
	current_row.add_child(current_instr_label)
	
	# Program counter display for current instruction
	var pc_label = create_label("  (PC: 0)", Color(0.7,0.7,0.7))
	pc_label.name = "PC_Display"
	pc_display_label = pc_label  # ← Store the reference
	current_row.add_child(pc_label)
	
	main.add_child(current_row)
	
	main.add_child(HSeparator.new())
	
	# Pipeline stages header
	var stages_header = create_label("PIPELINE STAGES", Color(1.0,0.8,0.3))
	main.add_child(stages_header)
	
	# Grid for pipeline stages
	var stage_grid = GridContainer.new()
	stage_grid.columns = 5
	stage_grid.add_theme_constant_override("h_separation", 30)
	main.add_child(stage_grid)
	
	# Stage names
	for name in ["IF", "ID", "EX", "MEM", "WB"]:
		var header = create_label(name, Color(0.5,0.9,0.5))
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stage_grid.add_child(header)
	
	# Stage instruction labels
	if_label = create_label("---", Color(0.3,0.8,1.0))
	id_label = create_label("---", Color(0.3,0.8,1.0))
	ex_label = create_label("---", Color(0.3,0.8,1.0))
	mem_label = create_label("---", Color(0.3,0.8,1.0))
	wb_label = create_label("---", Color(0.3,0.8,1.0))
	
	for label in [if_label, id_label, ex_label, mem_label, wb_label]:
		label.custom_minimum_size.x = 120
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stage_grid.add_child(label)
	
	main.add_child(HSeparator.new())
	
	# State registers header
	var state_header = create_label("STATE REGISTERS", Color(1.0,0.8,0.3))
	main.add_child(state_header)
	
	# State registers grid
	var state_grid = GridContainer.new()
	state_grid.columns = 3
	state_grid.add_theme_constant_override("h_separation", 30)
	main.add_child(state_grid)
	
	state_grid.add_child(create_label("Register", Color(0.7,0.7,0.7)))
	state_grid.add_child(create_label("PC", Color(0.7,0.7,0.7)))
	state_grid.add_child(create_label("Instruction", Color(0.7,0.7,0.7)))
	
	# IF/ID
	state_grid.add_child(create_label("IF/ID:", Color(0.7,0.7,0.7)))
	var if_id_pc = create_label("---", Color(0.7,0.7,0.7))
	var if_id_instr = create_label("---", Color.WHITE)
	if_id_label = if_id_instr
	# Store labels in dictionaries
	state_pc_labels["IF/ID"] = if_id_pc
	state_instr_labels["IF/ID"] = if_id_instr
	state_grid.add_child(if_id_pc)
	state_grid.add_child(if_id_instr)
	
	# ID/EX
	state_grid.add_child(create_label("ID/EX:", Color(0.7,0.7,0.7)))
	var id_ex_pc = create_label("---", Color(0.7,0.7,0.7))
	var id_ex_instr = create_label("---", Color.WHITE)
	id_ex_label = id_ex_instr
	state_pc_labels["ID/EX"] = id_ex_pc
	state_instr_labels["ID/EX"] = id_ex_instr
	state_grid.add_child(id_ex_pc)
	state_grid.add_child(id_ex_instr)
	
	# EX/MEM
	state_grid.add_child(create_label("EX/MEM:", Color(0.7,0.7,0.7)))
	var ex_mem_pc = create_label("---", Color(0.7,0.7,0.7))
	var ex_mem_instr = create_label("---", Color.WHITE)
	ex_mem_label = ex_mem_instr
	state_pc_labels["EX/MEM"] = ex_mem_pc
	state_instr_labels["EX/MEM"] = ex_mem_instr
	state_grid.add_child(ex_mem_pc)
	state_grid.add_child(ex_mem_instr)
	
	# MEM/WB
	state_grid.add_child(create_label("MEM/WB:", Color(0.7,0.7,0.7)))
	var mem_wb_pc = create_label("---", Color(0.7,0.7,0.7))
	var mem_wb_instr = create_label("---", Color.WHITE)
	mem_wb_label = mem_wb_instr
	state_pc_labels["MEM/WB"] = mem_wb_pc
	state_instr_labels["MEM/WB"] = mem_wb_instr
	state_grid.add_child(mem_wb_pc)
	state_grid.add_child(mem_wb_instr)
	
	
	main.add_child(HSeparator.new())
	
	# ALU section
	var alu_header = create_label("ALU", Color(1.0,0.8,0.3))
	main.add_child(alu_header)
	
	var alu_row = HBoxContainer.new()
	alu_row.add_child(create_label("Operation: ", Color(0.7,0.7,0.7)))
	alu_op_label = create_label("---", Color(1.0,0.8,0.3))
	alu_row.add_child(alu_op_label)
	alu_row.add_child(create_label("  Result: ", Color(0.7,0.7,0.7)))
	alu_result_label = create_label("0", Color(0.4,0.9,0.5))
	alu_row.add_child(alu_result_label)
	main.add_child(alu_row)

func create_label(text: String, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	return label

# Main function called by CPU - shifts instructions through pipeline
func clock_cycle(new_instruction: String):
	if not wb_label:
		print("ERROR: wb_label is null! Recreating UI...")
		create_ui()
	
	# WB gets MEM's instruction
	wb_instr = mem_instr
	wb_label.text = truncate(wb_instr)
	
	# MEM gets EX's instruction
	mem_instr = ex_instr
	mem_label.text = truncate(mem_instr)
	
	# EX gets ID's instruction
	ex_instr = id_instr
	ex_label.text = truncate(ex_instr)
	
	# ID gets IF's instruction
	id_instr = if_instr
	id_label.text = truncate(id_instr)
	
	# IF gets new instruction
	if_instr = new_instruction
	if_label.text = truncate(if_instr)
	
	# Update state registers with contents of the pipline stage directly before it
	if_id_label.text = truncate(if_instr)
	id_ex_label.text = truncate(id_instr)
	ex_mem_label.text = truncate(ex_instr)
	mem_wb_label.text = truncate(mem_instr)
	
	# Update current instruction display
	current_instr_label.text = truncate(new_instruction)

# Called by CPU to update ALU display
func set_alu(op: String, result: int):
	alu_operation = op
	alu_result = result
	alu_op_label.text = op
	alu_result_label.text = str(result)

# updates the ALU display
func update_alu(result: int, operation: String):
	if alu_op_label:
		alu_op_label.text = operation
	if alu_result_label:
		alu_result_label.text = str(result)

# update the program counter for the current instruction
func update_pc(pc_value: int):
	if pc_display_label:
		var byte_address = pc_value
		pc_display_label.text = "  (PC: " + str(byte_address) + ")"
		
	else:
		print("ERROR: pc_display_label not set!")
# Called by CPU to truncate(shorten) long strings (not used with updated formatting)
func truncate(text: String, max_len: int = 19) -> String:
	if text.length() > max_len:
		return text.substr(0, max_len - 3) + "..."
	return text

# Called by CPU when resetting
func reset():
	if_instr = "---"
	id_instr = "---"
	ex_instr = "---"
	mem_instr = "---"
	wb_instr = "---"
	
	if_label.text = "---"
	id_label.text = "---"
	ex_label.text = "---"
	mem_label.text = "---"
	wb_label.text = "---"
	
	if_id_label.text = "---"
	id_ex_label.text = "---"
	ex_mem_label.text = "---"
	mem_wb_label.text = "---"
	
	current_instr_label.text = "---"
	alu_op_label.text = "---"
	alu_result_label.text = "0"
	
	alu_operation = "---"
	alu_result = 0
	update_pc(0)
	clear_state_registers()

# Helper function to get what's in a stage (for debugging)
func get_stage(stage: String) -> String:
	match stage:
		"IF": return if_instr
		"ID": return id_instr
		"EX": return ex_instr
		"MEM": return mem_instr
		"WB": return wb_instr
	return "---"

# Populates selected stage with instruction
func update_stage(stage: String, instruction: String):
	match stage:
		"IF": if_label.text = truncate(instruction)
		"ID": id_label.text = truncate(instruction)
		"EX": ex_label.text = truncate(instruction)
		"MEM": mem_label.text = truncate(instruction)
		"WB": wb_label.text = truncate(instruction)

# Populates selected state register with content/instruction 
func update_state_register(reg: String, pc: int, content: String):
	print("Updating ", reg, " PC to ", pc)
	match reg:
		"IF/ID":
			state_pc_labels["IF/ID"].text = str(pc)
			state_instr_labels["IF/ID"].text = truncate(content)
		"ID/EX":
			state_pc_labels["ID/EX"].text = str(pc)
			state_instr_labels["ID/EX"].text = truncate(content)
		"EX/MEM":
			state_pc_labels["EX/MEM"].text = str(pc)
			state_instr_labels["EX/MEM"].text = truncate(content)
		"MEM/WB":
			state_pc_labels["MEM/WB"].text = str(pc)
			state_instr_labels["MEM/WB"].text = truncate(content)
			
func clear_state_registers():
	
	state_pc_labels["IF/ID"].text = "---"
	state_instr_labels["IF/ID"].text = "---"
	state_pc_labels["ID/EX"].text = "---"
	state_instr_labels["ID/EX"].text = "---"
	state_pc_labels["EX/MEM"].text = "---"
	state_instr_labels["EX/MEM"].text = "---"
	state_pc_labels["MEM/WB"].text = "---"
	state_instr_labels["MEM/WB"].text = "---"
