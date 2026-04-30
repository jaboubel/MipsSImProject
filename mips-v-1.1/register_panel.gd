extends Panel

var value_labels = {}

func _ready():
	create_display()

func create_display():
	# Clear existing
	for child in get_children():
		child.queue_free()
	
	# Simple VBoxContainer (no scroll for now)
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	
	# Title
	var title = Label.new()
	title.text = "REGISTERS"
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	title.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(title)
	
	# Separator
	var sep = HSeparator.new()
	main_vbox.add_child(sep)
	
	# Create a grid for compact display (1 column)
	var grid = GridContainer.new()
	grid.columns = 1
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 4)
	main_vbox.add_child(grid)
	
	# All 32 registers
	var all_regs = [
		"zero", "at", "v0", "v1", "a0", "a1", "a2", "a3",
		"t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7",
		"s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7",
		"t8", "t9", "k0", "k1", "gp", "sp", "fp", "ra"
	]
	
	for reg in all_regs:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		
		# Register name
		var name_label = Label.new()
		name_label.text = "$" + reg
		name_label.custom_minimum_size.x = 35
		name_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		name_label.add_theme_font_size_override("font_size", 11)
		
		# Register value
		var value_label = Label.new()
		var initial_value = 0
		if reg == "sp":
			initial_value = 0x7FFFFFFF
			value_label.text = "0x7FFFFFFF"
		else:
			value_label.text = "0"
		value_label.custom_minimum_size.x = 65
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_color_override("font_color", Color.WHITE)
		value_label.add_theme_font_size_override("font_size", 11)
		
		hbox.add_child(name_label)
		hbox.add_child(value_label)
		grid.add_child(hbox)
		
		value_labels[reg] = value_label
	
	# Make sure panel is visible
	visible = true
	print("Register panel created with ", value_labels.size(), " registers")

func update_register(reg: String, value: int):
	if value_labels.has(reg) and reg != "zero":
		if reg == "sp" or value > 9999 or value < 0:
			# Show hex for large values
			value_labels[reg].text = "0x" + dec_to_hex(value)
		else:
			value_labels[reg].text = str(value)
	elif reg == "zero" and value_labels.has(reg):
		value_labels[reg].text = "0"

func dec_to_hex(val: int) -> String:
	if val == 0:
		return "0"
	var hex_chars = "0123456789ABCDEF"
	var result = ""
	var temp = val
	if temp < 0:
		temp = temp & 0xFFFFFFFF
	while temp > 0:
		result = hex_chars[temp % 16] + result
		temp = temp / 16
	return result
