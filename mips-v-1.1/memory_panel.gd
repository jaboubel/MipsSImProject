extends Panel

@onready var scroll_container = $ScrollContainer
@onready var memory_columns = $ScrollContainer/MemoryColumns

var memory_labels = {}  # address -> value label

func _ready():
	create_display()

func create_display():
	# Clear existing
	for child in memory_columns.get_children():
		child.queue_free()
	memory_labels.clear()
	
	# Create 4 columns (VBoxContainers)
	var columns = []
	for i in range(4):
		var col = VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		col.size_flags_horizontal = Control.SIZE_EXPAND
		memory_columns.add_child(col)
		columns.append(col)
	
	# Show ALL 1024 words (addresses 0 to 4092)
	var total_words = 1024  # 4096 bytes / 4 = 1024 words
	var words_per_column = total_words / 4  # 256 words per column
	
	for col_idx in range(4):
		var col = columns[col_idx]
		for row_idx in range(words_per_column):
			var word_index = col_idx * words_per_column + row_idx
			var addr = word_index * 4
			if addr >= 4096:  # Safety check
				break
			
			# Row container for address + value
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			row.custom_minimum_size.y = 25
			
			# Address label
			var addr_label = Label.new()
			addr_label.text = "0x" + dec_to_hex(addr) + ":"
			addr_label.add_theme_color_override("font_color", Color.CYAN)
			addr_label.custom_minimum_size.x = 60
			
			# Value label
			var val_label = Label.new()
			val_label.text = "0"
			val_label.add_theme_color_override("font_color", Color.YELLOW)
			val_label.custom_minimum_size.x = 70
			val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			
			row.add_child(addr_label)
			row.add_child(val_label)
			col.add_child(row)
			
			memory_labels[addr] = val_label
	
	print("Memory panel created with ", memory_labels.size(), " entries (", words_per_column, " per column)")

func dec_to_hex(val: int) -> String:
	if val == 0:
		return "0"
	var hex = "0123456789ABCDEF"
	var res = ""
	var t = val
	while t > 0:
		res = hex[t % 16] + res
		t = t / 16
	return res

func update_memory(address: int, value: int):
	var aligned = address & 0xFFFFFFFC
	if memory_labels.has(aligned):
		memory_labels[aligned].text = str(value)
		print("Memory[", aligned, "] = ", value)

func reset_display():
	for addr in memory_labels.keys():
		memory_labels[addr].text = "0"
