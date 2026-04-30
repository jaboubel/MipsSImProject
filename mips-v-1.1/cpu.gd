extends Node

@onready var code_editor = $"../Panel_Code/CodeEdit"
@onready var control_panel = $"../HBoxContainerControls"
@onready var register_panel = $"../Panel_Registers"
@onready var pipeline_panel = $"../Panel_Pipeline"
@onready var memory_panel = $"../Panel_Memory"

# ===== REGISTER FILE =====
var registers = {
	"zero":0, "at":0, "v0":0, "v1":0,
	"a0":0, "a1":0, "a2":0, "a3":0,
	"t0":0, "t1":0, "t2":0, "t3":0, "t4":0, "t5":0, "t6":0, "t7":0,
	"s0":0, "s1":0, "s2":0, "s3":0, "s4":0, "s5":0, "s6":0, "s7":0,
	"t8":0, "t9":0, "k0":0, "k1":0, "gp":0, "sp":0x7FFFFFFF, "fp":0, "ra":0
}

# ===== DATA MEMORY =====
var data_memory = {}
const MEMORY_SIZE = 4096

# ===== PIPELINE STATE REGISTERS =====
# IF/ID Register
var if_id = {
	"instruction": "",
	"pc": 0,
	"valid": false
}

# ID/EX Register
var id_ex = {
	"pc": 0,
	"opcode": "",
	"rs": 0,           # Register number
	"rt": 0,
	"rd": 0,
	"rs_value": 0,     # Actual value
	"rt_value": 0,
	"immediate": 0,
	"funct": 0,
	"branch_target": 0,
	"control": {
		"reg_write": false,
		"reg_dst": false,
		"alu_src": false,
		"mem_read": false,
		"mem_write": false,
		"mem_to_reg": false,
		"branch": false,
		"jump": false,
		"alu_op": ""      # ALU operation
	},
	"valid": false
}

# EX/MEM Register
var ex_mem = {
	"pc": 0,
	"alu_result": 0,
	"rt_value": 0,
	"write_reg_addr": 0,
	"control": {
		"reg_write": false,
		"mem_read": false,
		"mem_write": false,
		"mem_to_reg": false
	},
	"valid": false
}

# MEM/WB Register
var mem_wb = {
	"pc": 0,
	"alu_result": 0,
	"mem_data": 0,
	"write_reg_addr": 0,
	"control": {
		"reg_write": false,
		"mem_to_reg": false
	},
	"valid": false
}

# ===== PROGRAM STATE =====
var program = []      # List of parsed instructions
var labels = {}       # Label name -> byte address
var pc = 0            # Program counter
var cycles = 0
var is_running = false
var timer: Timer
var debug_mode = true

# ===== INSTRUCTION DECODE TABLE =====
var opcode_map = {
	"add":   {"opcode": 0x00, "type": "R"},
	"addi":  {"opcode": 0x08, "type": "I"},
	"sub":   {"opcode": 0x00, "type": "R", "funct": 0x22},
	"mul":   {"opcode": 0x00, "type": "R", "funct": 0x18},
	"and":   {"opcode": 0x00, "type": "R", "funct": 0x24},
	"or":    {"opcode": 0x00, "type": "R", "funct": 0x25},
	"sll":   {"opcode": 0x00, "type": "R", "funct": 0x00},
	"srl":   {"opcode": 0x00, "type": "R", "funct": 0x02},
	"lw":    {"opcode": 0x23, "type": "I"},
	"sw":    {"opcode": 0x2B, "type": "I"},
	"beq":   {"opcode": 0x04, "type": "I"},
	"j":     {"opcode": 0x02, "type": "J"},
	"nop":   {"opcode": 0x00, "type": "R", "funct": 0x00}
}

var register_numbers = {
	"zero":0, "at":1, "v0":2, "v1":3, "a0":4, "a1":5, "a2":6, "a3":7,
	"t0":8, "t1":9, "t2":10, "t3":11, "t4":12, "t5":13, "t6":14, "t7":15,
	"s0":16, "s1":17, "s2":18, "s3":19, "s4":20, "s5":21, "s6":22, "s7":23,
	"t8":24, "t9":25, "k0":26, "k1":27, "gp":28, "sp":29, "fp":30, "ra":31
}

# ===== INITIALIZATION =====
func _ready():
	# Initialize memory
	for i in range(MEMORY_SIZE):
		data_memory[i] = 0
	
	# Connect signals
	control_panel.step_pressed.connect(_on_step)
	control_panel.run_pressed.connect(_on_run)
	control_panel.reset_pressed.connect(_on_reset)
	control_panel.speed_changed.connect(_on_speed)
	
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_clock_cycle)
	
	setup_editor()
	load_demo()
	update_displays()
	
	print("5-Stage Pipelined MIPS Simulator Ready")
	print_debug_state()

# ===== EDITOR SETUP =====
func setup_editor():
	var highlighter = CodeHighlighter.new()
	var instructions = ["add", "addi", "sub", "mul", "and", "or", "sll", "srl", "lw", "sw", "beq", "j", "nop"]
	for instr in instructions:
		highlighter.add_keyword_color(instr, Color(0.3, 0.8, 1.0))
		highlighter.add_keyword_color(instr.to_upper(), Color(0.3, 0.8, 1.0))
	
	var regs = ["t0", "t1", "t2", "t3", "s0", "s1", "zero", "a0", "v0", "sp", "ra"]
	for r in regs:
		highlighter.add_keyword_color(r, Color(1.0, 0.8, 0.3))
	
	highlighter.number_color = Color(0.4, 0.9, 0.5)
	highlighter.symbol_color = Color(0.6, 0.6, 0.6)
	
	code_editor.syntax_highlighter = highlighter
	code_editor.add_theme_color_override("background_color", Color(0.1, 0.1, 0.15))
	code_editor.add_theme_color_override("font_color", Color.WHITE)

func load_demo():
	code_editor.text = """
# Test all MIPS instructions
main:
    # Setup initial values
    addi $t0, $zero, 12      # $t0 = 12
    addi $t1, $zero, 5       # $t1 = 5
    addi $t2, $zero, 2       # $t2 = 2
    nop                      
    nop
    nop

    # Arithmetic
    add $t3, $t0, $t1        # 12+5=17
    sub $t4, $t0, $t1        # 12-5=7
    mul $t5, $t0, $t1        # 12*5=60

    # Bitwise
    and $t6, $t0, $t1        # 12&5 = 4 (1100 & 0101 = 0100)
    or  $t7, $t0, $t1        # 12|5 = 13 (1100 | 0101 = 1101)

    # Shifts
    sll $s0, $t0, $t2        # 12 << 2 = 48
    srl $s1, $t0, $t2        # 12 >> 2 = 3

    # Memory store/load
    sw $t3, 0($zero)         # store 17 at address 0
    sw $t4, 4($zero)         # store 7 at address 4
    nop
    nop
    nop
    lw $s2, 0($zero)         # load 17 into $s2
    lw $s3, 4($zero)         # load 7 into $s3

    # Branch (skip two instructions if equal)
    addi $t8, $zero, 10
    addi $t9, $zero, 10
    nop
    nop
    nop
    beq $t8, $t9, 2       # skip two instructions if equal
    addi $s4, $zero, 999     # skipped
    addi $s5, $zero, 888     # skipped
skip:
    addi $s6, $zero, 777     # executed after branch

    # Jump to end (skip the next instruction)
    j end
    addi $s7, $zero, 666     # skipped
end:
    sw $s6, 8($zero)         # store 777 at address 8
"""

func parse_program():
	program.clear()
	var lines = code_editor.text.split("\n")
	# First pass: collect label addresses
	var labels = {}
	var current_addr = 0
	for line in lines:
		var trimmed = line.strip_edges()
		if trimmed == "" or trimmed.begins_with("#"):
			continue
		if trimmed.ends_with(":"):
			var label = trimmed.trim_suffix(":")
			labels[label] = current_addr * 4   # byte address
		else:
			current_addr += 1
	
	# Second pass: parse instructions, replacing labels with their addresses
	var address = 0
	for line in lines:
		var trimmed = line.strip_edges()
		if trimmed == "" or trimmed.begins_with("#") or trimmed.ends_with(":"):
			continue
		
		var instr_text = trimmed
		var parts = instr_text.split(" ")
		var op = parts[0].to_lower()
		
		# For j and beq, replace label with its numeric address
		if op in ["j", "beq"] and parts.size() >= 2:
			var target = parts[1]
			if target in labels:
				var target_addr = labels[target]
				instr_text = op + " " + str(target_addr)
				
		program.append({
			"text": instr_text,
			"address": address * 4,
			"binary": encode_instruction(instr_text)
		})
		address += 1
	
	print("Loaded ", program.size(), " instructions")
	for instr in program:
		print("  ", instr["address"], ": ", instr["text"], " -> ", instr["binary"])

func encode_instruction(asm: String) -> String:
	var parts = asm.replace(",", " ").split(" ", false)
	var op = parts[0].to_lower()
	
	if op == "nop":
		return "00000000000000000000000000000000"
	
	var info = opcode_map.get(op, {})
	
	if info.get("type") == "R":
		var funct = info.get("funct", 0x20)
		var rd = 0
		var rs = 0
		var rt = 0
		var shamt = 0
		
		match op:
			"add", "sub", "mul", "and", "or":
				if parts.size() >= 4:
					rd = register_numbers.get(parts[1].replace("$", ""), 0)
					rs = register_numbers.get(parts[2].replace("$", ""), 0)
					rt = register_numbers.get(parts[3].replace("$", ""), 0)
			"sll", "srl":
				if parts.size() >= 4:
					rd = register_numbers.get(parts[1].replace("$", ""), 0)
					rt = register_numbers.get(parts[2].replace("$", ""), 0)
					shamt = int(parts[3])
		
		return format_binary(0x00, 6) + format_binary(rs, 5) + format_binary(rt, 5) + format_binary(rd, 5) + format_binary(shamt, 5) + format_binary(funct, 6)
	
	elif info.get("type") == "I":
		var opcode = info.get("opcode", 0)
		var rs = 0
		var rt = 0
		var imm = 0
		
		match op:
			"addi", "beq":
				if parts.size() >= 4:
					rt = register_numbers.get(parts[1].replace("$", ""), 0)
					rs = register_numbers.get(parts[2].replace("$", ""), 0)
					imm = int(parts[3]) if parts[3].is_valid_int() else 0
			"lw", "sw":
				if parts.size() >= 3:
					rt = register_numbers.get(parts[1].replace("$", ""), 0)
					var offset_parts = parts[2].split("(")
					imm = int(offset_parts[0]) if offset_parts[0].is_valid_int() else 0
					rs = register_numbers.get(offset_parts[1].replace(")", "").replace("$", ""), 0)
		
		return format_binary(opcode, 6) + format_binary(rs, 5) + format_binary(rt, 5) + format_binary(imm & 0xFFFF, 16)
	
	elif info.get("type") == "J":
		return format_binary(0x02, 6) + format_binary(0, 26)
	
	return ""

func format_binary(value: int, bits: int) -> String:
	var result = ""
	for i in range(bits-1, -1, -1):
		result += "1" if (value >> i) & 1 else "0"
	return result

# ===== PIPELINE EXECUTION =====
func _clock_cycle():
	if is_running:
		pipeline_cycle()

func pipeline_cycle():
	cycles += 1
	print("\n=== CYCLE ", cycles, " ===")
	
	# STAGE 5: Write Back
	write_back_stage()
	
	# STAGE 4: Memory
	memory_stage()
	
	# STAGE 3: Execute
	execute_stage()
	
	# STAGE 2: Decode
	decode_stage()
	
	# STAGE 1: Fetch
	fetch_stage()
	
	# Update displays
	update_displays()
	
	# Print debug info
	if debug_mode:
		print_debug_state()
	
	# Check if program finished
	if not if_id.valid and not id_ex.valid and not ex_mem.valid and not mem_wb.valid and pc >= program.size():
		print("\n=== PROGRAM COMPLETED in ", cycles, " cycles ===")
		stop()

func fetch_stage():
	var pc_index = pc/4
	if pc_index < program.size():
		var instr = program[pc_index]
		if_id.instruction = instr["text"]
		if_id.pc = pc
		print("FETCH: Setting IF/ID PC to ", pc)
		if_id.valid = true
		
		pipeline_panel.update_pc(pc)
		pipeline_panel.clock_cycle(instr["text"])  # ← Pass full instruction!
		
		
		
		print("  IF: PC=", pc, " -> ", instr["text"])
		
		pc += 4
	else:
		if_id.valid = false
		pipeline_panel.clock_cycle("---")
	pipeline_panel.update_state_register("IF/ID", if_id.pc, if_id.instruction)
	

func decode_stage():
	if not if_id.valid:
		print("  ID: Stall (no instruction)")
		pipeline_panel.update_stage("ID", "---")
		id_ex.valid = false
		return
	
	var instr_text = if_id.instruction
	var parts = instr_text.replace(",", " ").split(" ", false)
	var op = parts[0].to_lower()
	
	# Extract register numbers and values
	var rs_num = 0
	var rt_num = 0
	var rd_num = 0
	var rs_value = 0
	var rt_value = 0
	var immediate = 0
	var funct = 0
	
	match op:
		"add", "sub", "mul", "and", "or":
			if parts.size() >= 4:
				rd_num = register_numbers.get(parts[1].replace("$", ""), 0)
				rs_num = register_numbers.get(parts[2].replace("$", ""), 0)
				rt_num = register_numbers.get(parts[3].replace("$", ""), 0)
				rs_value = get_reg_value_by_num(rs_num)
				rt_value = get_reg_value_by_num(rt_num)
				funct = opcode_map.get(op, {}).get("funct", 0x20)
		
		"addi":
			if parts.size() >= 4:
				rt_num = register_numbers.get(parts[1].replace("$", ""), 0)
				rs_num = register_numbers.get(parts[2].replace("$", ""), 0)
				immediate = int(parts[3])
				rs_value = get_reg_value_by_num(rs_num)
		
		"lw", "sw":
			if parts.size() >= 3:
				rt_num = register_numbers.get(parts[1].replace("$", ""), 0)
				rt_value = get_reg_value_by_num(rt_num)
				var offset_parts = parts[2].split("(")
				immediate = int(offset_parts[0]) if offset_parts[0].is_valid_int() else 0
				rs_num = register_numbers.get(offset_parts[1].replace(")", "").replace("$", ""), 0)
				rs_value = get_reg_value_by_num(rs_num)
				
				print("DEBUG LW/SW: parts[2]='", parts[2], "' -> offset=", offset_parts[0], " immediate=", immediate)  # Add this
		"sll", "srl":
			if parts.size() >= 4:
				rd_num = register_numbers.get(parts[1].replace("$", ""), 0)
				rt_num = register_numbers.get(parts[2].replace("$", ""), 0)
				immediate = int(parts[3])      # shift amount (0‑31)
				rt_value = get_reg_value_by_num(rt_num)
		"beq":
			if parts.size() >= 4:
				rs_num = register_numbers.get(parts[1].replace("$", ""), 0)
				rt_num = register_numbers.get(parts[2].replace("$", ""), 0)
				immediate = int(parts[3])   # should be 2, not -6
				rs_value = get_reg_value_by_num(rs_num)
				rt_value = get_reg_value_by_num(rt_num)
				# Debug: print what we got
				print("BEQ immediate parsed as: ", immediate)
				
		"j":
			if parts.size() >= 2:
				immediate = int(parts[1])
		"nop":
			pass  # No register operands
	
	# Generate control signals
	var control = generate_control_signals(op)
	
	# Pass to ID/EX register
	id_ex.pc = if_id.pc
	id_ex.opcode = op
	id_ex.rs = rs_num
	id_ex.rt = rt_num
	id_ex.rd = rd_num
	id_ex.rs_value = rs_value
	id_ex.rt_value = rt_value
	id_ex.immediate = immediate
	id_ex.funct = funct
	id_ex.control = control
	id_ex.valid = true
	
	print("  ID: ", instr_text, " -> rs=$", get_reg_name(rs_num), "=", rs_value, " rt=$", get_reg_name(rt_num), "=", rt_value)
	pipeline_panel.update_stage("ID", instr_text)
	
	# Update pipeline panel state registers
	pipeline_panel.update_state_register("ID/EX", id_ex.pc, instr_text)
	#and do the same for the next ones,,, this one becomes id/ex

func execute_stage():
	if not id_ex.valid:
		print("  EX: Stall (no instruction)")
		pipeline_panel.update_stage("EX", "---")
		ex_mem.valid = false
		return
	print("DEBUG EXECUTE: op=", id_ex.opcode, " rs_value=", id_ex.rs_value, " immediate=", id_ex.immediate)
	var alu_result = 0
	var op = id_ex.opcode
	var alu_op = id_ex.control.get("alu_op", "")
	
	match alu_op:
		"ADD":
			alu_result = id_ex.rs_value + id_ex.rt_value
		"ADDI":
			alu_result = id_ex.rs_value + id_ex.immediate
		"SUB":
			alu_result = id_ex.rs_value - id_ex.rt_value
		"MUL":
			alu_result = id_ex.rs_value * id_ex.rt_value
		"AND":
			alu_result = id_ex.rs_value & id_ex.rt_value
		"OR":
			alu_result = id_ex.rs_value | id_ex.rt_value
		"SLL":
			alu_result = id_ex.rt_value << id_ex.immediate
		"SRL":
			alu_result = id_ex.rt_value >> id_ex.immediate
		"BEQ":
			alu_result = 1 if (id_ex.rs_value == id_ex.rt_value) else 0
		_:
			alu_result = id_ex.rs_value + id_ex.immediate  # Default ADDI
	if id_ex.opcode == "beq" and alu_result == 0:
		var branch_target = id_ex.pc + 4 + (id_ex.immediate << 2)
		print("  Branch taken to PC=", branch_target)
		pc = branch_target
		# flush pipeline
		if_id.valid = false
		id_ex.valid = false
		ex_mem.valid = false
		return   # skip the rest of this execute stage (no EX/MEM write)

	if id_ex.opcode == "j":
		# jump target: PC = (PC[31:28] << 28) | (immediate << 2)
		
		pc = id_ex.immediate
		if_id.valid = false
		id_ex.valid = false
		ex_mem.valid = false
		print("  Jump to PC=", pc)
		return
	# Determine write register address
	var write_reg_addr = 0
	if id_ex.control.get("reg_dst", false):
		write_reg_addr = id_ex.rd  # R-type: write to rd
	else:
		write_reg_addr = id_ex.rt  # I-type: write to rt
	
	# Pass to EX/MEM register
	ex_mem.pc = id_ex.pc
	ex_mem.alu_result = alu_result
	ex_mem.rt_value = id_ex.rt_value
	ex_mem.write_reg_addr = write_reg_addr
	ex_mem.control = {
		"reg_write": id_ex.control.get("reg_write", false),
		"mem_read": id_ex.control.get("mem_read", false),
		"mem_write": id_ex.control.get("mem_write", false),
		"mem_to_reg": id_ex.control.get("mem_to_reg", false)
	}
	ex_mem.valid = true
	
	print("  EX: ", op, " -> ALU result = ", alu_result)
	pipeline_panel.update_stage("EX", op)
	if op == "lw" or op == "sw":
		pipeline_panel.update_alu(alu_result, "ADDI")
	else:
		pipeline_panel.update_alu(alu_result, op.to_upper())

	pipeline_panel.update_state_register("EX/MEM", id_ex.pc, op)

func memory_stage():
	if not ex_mem.valid:
		print("  MEM: Stall (no instruction)")
		pipeline_panel.update_stage("MEM", "---")
		mem_wb.valid = false
		return
	
	var mem_data = 0
	
	# Memory operations
	if ex_mem.control.get("mem_read", false):
		var address = ex_mem.alu_result
		mem_data = data_memory.get(address, 0)
		print("  MEM: LW - address=", address, " value=", mem_data)
	
	if ex_mem.control.get("mem_write", false):
		var address = ex_mem.alu_result
		data_memory[address] = ex_mem.rt_value
		print("  MEM: SW - address=", address, " value=", ex_mem.rt_value)
		if memory_panel:
			memory_panel.update_memory(address, ex_mem.rt_value)
	
	# Pass to MEM/WB register
	mem_wb.pc = ex_mem.pc
	mem_wb.alu_result = ex_mem.alu_result
	mem_wb.mem_data = mem_data
	mem_wb.write_reg_addr = ex_mem.write_reg_addr
	mem_wb.control = {
		"reg_write": ex_mem.control.get("reg_write", false),
		"mem_to_reg": ex_mem.control.get("mem_to_reg", false)
	}
	mem_wb.valid = true
	
	var mem_active = ex_mem.control.get("mem_read", false) or ex_mem.control.get("mem_write", false)
	pipeline_panel.update_stage("MEM", "MEM" if mem_active else "---")
	pipeline_panel.update_state_register("MEM/WB", ex_mem.pc, "alu=" + str(ex_mem.alu_result))
#"MEM/WB", mem_wb.pc
func write_back_stage():
	if not mem_wb.valid:
		print("  WB: Stall (no instruction)")
		pipeline_panel.update_stage("WB", "---")
		return
	
	var write_data = 0
	
	if mem_wb.control.get("mem_to_reg", false):
		write_data = mem_wb.mem_data
	else:
		write_data = mem_wb.alu_result
	
	# Write to register file
	if mem_wb.control.get("reg_write", false) and mem_wb.write_reg_addr != 0:  # Don't write to $zero
		var reg_name = get_reg_name(mem_wb.write_reg_addr)
		set_reg_value_by_num(mem_wb.write_reg_addr, write_data)
		print("  WB: Write $", reg_name, " = ", write_data)
	
	pipeline_panel.update_stage("WB", "WB")
	#pipeline_panel.update_state_register("MEM/WB", mem_wb.pc, "write=$" + get_reg_name(mem_wb.write_reg_addr) + "=" + str(write_data))

func generate_control_signals(op: String) -> Dictionary:
	var signals = {
		"reg_write": false,
		"reg_dst": false,
		"alu_src": false,
		"mem_read": false,
		"mem_write": false,
		"mem_to_reg": false,
		"branch": false,
		"jump": false,
		"alu_op": ""
	}
	
	match op:
		"add", "sub", "mul", "and", "or", "sll", "srl":
			signals.reg_write = true
			signals.reg_dst = true
			signals.alu_op = op.to_upper()
		
		"addi":
			signals.reg_write = true
			signals.alu_src = true
			signals.alu_op = "ADDI"
		
		"lw":
			signals.reg_write = true
			signals.alu_src = true
			signals.mem_read = true
			signals.mem_to_reg = true
			signals.alu_op = "ADDI"
		
		"sw":
			signals.alu_src = true
			signals.mem_write = true
			signals.alu_op = "ADDI"
		
		"beq":
			signals.branch = true
			signals.alu_op = "SUB"
		
		"j":
			signals.jump = true
		
		"nop":
			pass  # All signals false
	
	return signals

# ===== HELPER FUNCTIONS =====
func get_reg_value_by_num(num: int) -> int:
	for reg_name in register_numbers:
		if register_numbers[reg_name] == num:
			return registers.get(reg_name, 0)
	return 0

func set_reg_value_by_num(num: int, value: int):
	if num == 0:  # $zero is hardwired to 0
		return
	for reg_name in register_numbers:
		if register_numbers[reg_name] == num:
			registers[reg_name] = value
			return

func get_reg_name(num: int) -> String:
	for reg_name in register_numbers:
		if register_numbers[reg_name] == num:
			return reg_name
	return "unknown"

func get_reg(name: String) -> int:
	return registers.get(name, 0)

func set_reg(name: String, value: int):
	if name != "zero":
		registers[name] = value

# ===== CONTROL BUTTON HANDLERS =====
func _on_step():
	if is_running:
		stop()
	parse_program()
	pipeline_cycle()

func _on_run():
	if is_running:
		stop()
	else:
		start()

func _on_reset():
	stop()
	reset()

func _on_speed(value: float):
	timer.wait_time = 1.0 / value

func start():
	is_running = true
	control_panel.set_running(true)
	timer.start()
	print("=== RUNNING ===")

func stop():
	is_running = false
	control_panel.set_running(false)
	timer.stop()
	print("=== STOPPED at cycle ", cycles, " ===")

func reset():
	is_running = false
	timer.stop()
	
	# Reset program state
	pc = 0
	cycles = 0
	
	# Reset registers
	for r in registers.keys():
		if r == "sp":
			registers[r] = 0x7FFFFFFF
		elif r == "zero":
			registers[r] = 0
		else:
			registers[r] = 0
	
	# Clear memory
	for i in range(MEMORY_SIZE):
		data_memory[i] = 0
	
	# Clear pipeline registers
	if_id = {"instruction": "", "pc": 0, "valid": false}
	id_ex = {"pc": 0, "opcode": "", "rs": 0, "rt": 0, "rd": 0, "rs_value": 0, "rt_value": 0, "immediate": 0, "funct": 0, "control": {}, "valid": false}
	ex_mem = {"alu_result": 0, "rt_value": 0, "write_reg_addr": 0, "control": {}, "valid": false}
	mem_wb = {"alu_result": 0, "mem_data": 0, "write_reg_addr": 0, "control": {}, "valid": false}
	
	# Reset displays
	pipeline_panel.reset()
	update_displays()
	
	control_panel.set_running(false)
	print("=== RESET ===")

func update_displays():
	# Update register display
	for r in registers.keys():
		register_panel.update_register(r, registers[r])

func print_debug_state():
	print("\n--- DEBUG STATE ---")
	print("PC: ", pc)
	print("\nRegisters:")
	for r in ["t0", "t1", "t2", "t3", "t4", "s0", "s1", "sp", "ra"]:
		print("  $", r, " = ", registers[r])
	
	print("\nPipeline State Registers:")
	print("  IF/ID: ", if_id.instruction if if_id.valid else "empty")
	print("  ID/EX: ", id_ex.opcode if id_ex.valid else "empty")
	print("  EX/MEM: ALU=", ex_mem.alu_result if ex_mem.valid else "empty")
	print("  MEM/WB: Write=$", get_reg_name(mem_wb.write_reg_addr) if mem_wb.valid else "empty")
	
	print("--------------------\n")

func _execute_next():
	if is_running:
		pipeline_cycle()
