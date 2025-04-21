extends Node


var fileDialog : FileDialog
var richLabel : RichTextLabel
var codeEdit : CodeEdit
var timer : Timer
var help : CanvasLayer
var shortcutShow : CheckBox
var consoleLabel : Label

# TODO: Figure out a way to do this cleanly
func init():
	fileDialog = get_node('/root/Root/FileDialog')
	richLabel = get_node('/root/Root/BoxContainer/TopContainer/RichTextLabel')
	codeEdit = get_node('/root/Root/BoxContainer/SplitContainer/CodeEdit')
	timer = get_node('/root/Root/Timer')
	help = get_node('/root/Root/CanvasLayer')
	shortcutShow = get_node('/root/Root/CanvasLayer/ShortcutPanel/MarginContainer/ShortcutShow')
	consoleLabel = get_node('/root/Root/BoxContainer/SplitContainer/ConsoleLabel')


var filePath = ""
var configPath = "user://azria_editor.conf"

func process_input():
	if Input.is_action_pressed("block"):
		codeEdit.editable = false
	elif Input.is_action_just_released("block"):
		codeEdit.editable = true
	
	if Input.is_action_just_pressed("open_config"):
		filePath = configPath
		var fileRead = FileAccess.open(filePath, FileAccess.READ)
		richLabel.text = "[center]%s[/center]" % filePath
		codeEdit.text = fileRead.get_as_text()
		fileRead.close()
	
	if Input.is_action_just_pressed("undo"):
		codeEdit.editable = true
		codeEdit.undo()
	
	elif Input.is_action_just_pressed("file_save"):
		var fileWrite = FileAccess.open(filePath, FileAccess.WRITE)
		
		fileWrite.store_string(codeEdit.text)
		fileWrite.close()
		richLabel.text = "[center]%s - saved[/center]" % filePath
		timer.start(5)
	
	elif Input.is_action_just_pressed("file_open"):
		fileDialog.visible = true
	
	elif Input.is_action_just_pressed("run_code"):
		var exeName = filePath.split(".")[0]
		
		match OS.get_name(): #needs lang file implementation
			"Windows":
				#var exe = OS.execute_with_pipe("gcc", [filePath, "-o", exeName])
				#if exe == {}:
					#print("NULL")
				print("Welcome to Windows")
			"macOS":
				print("Welcome to macOS!")
			"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
				# TODO: make code more generic
				
				var exe = OS.execute_with_pipe("gcc", [filePath, "-o", exeName])
				
				richLabel.text = "[center]%s - executed[/center]" % filePath
				timer.start(5)
				
				exe = OS.execute_with_pipe(exeName, [])
				
				if exe["stdio"].is_open():
					var buffer = PackedByteArray()
					while true:
						buffer.append_array(exe["stdio"].get_buffer(2048))
						if exe["stdio"].get_error() != OK:
							print(buffer)
							break;
					
					if not buffer.is_empty():
						consoleLabel.text = buffer.get_string_from_utf8()
			"Android":
				print("Welcome to Android!")
			"iOS":
				print("Welcome to iOS!")
			"Web":
				print("Welcome to the Web!")
	
	elif Input.is_action_just_pressed("select_left"):
		var selectCol = codeEdit.get_selection_to_column()
		var selectLine = codeEdit.get_selection_to_line()
		var caretCol = codeEdit.get_caret_column()
		var caretLine = codeEdit.get_caret_line()
		codeEdit.select(selectLine, selectCol, caretLine, caretCol - 1)
	
	elif Input.is_action_just_pressed("select_right"):
		var selectCol = codeEdit.get_selection_from_column()
		var selectLine = codeEdit.get_selection_from_line()
		var caretCol = codeEdit.get_caret_column()
		var caretLine = codeEdit.get_caret_line()
		codeEdit.select(selectLine, selectCol, caretLine, caretCol + 1)
	
	elif Input.is_action_just_pressed("select_up"):
		var selectCol = codeEdit.get_selection_to_column()
		var selectLine = codeEdit.get_selection_to_line()
		var caretCol = codeEdit.get_caret_column()
		var caretLine = codeEdit.get_caret_line()
		codeEdit.select(selectLine, selectCol, caretLine - 1, caretCol)
	
	elif Input.is_action_just_pressed("select_down"):
		var selectCol = codeEdit.get_selection_from_column()
		var selectLine = codeEdit.get_selection_from_line()
		var caretCol = codeEdit.get_caret_column()
		var caretLine = codeEdit.get_caret_line()
		codeEdit.select(selectLine, selectCol, caretLine + 1, caretCol)
	
	elif Input.is_action_just_pressed("caret_beginning_line"):
		codeEdit.set_caret_column(0)
	
	elif Input.is_action_just_pressed("caret_end_line"):
		var currentLine = codeEdit.get_caret_line()
		codeEdit.set_caret_column(len(codeEdit.get_line(currentLine)))
	
	elif Input.is_action_just_pressed("caret_beginning_para"):
		var currentLine = codeEdit.get_caret_line()
		var begParaLine = find_para_beginning(currentLine)
		codeEdit.set_caret_line(begParaLine)
		codeEdit.set_caret_column(codeEdit.get_first_non_whitespace_column(begParaLine))
	
	elif Input.is_action_just_pressed("caret_end_para"):
		var currentLine = codeEdit.get_caret_line()
		var endParaLine = find_para_end(currentLine)
		codeEdit.set_caret_line(endParaLine)
		codeEdit.set_caret_column(codeEdit.get_first_non_whitespace_column(endParaLine))
	
	elif Input.is_action_just_pressed("caret_left"):
		codeEdit.deselect()
		var currentCol = codeEdit.get_caret_column()
		codeEdit.set_caret_column(currentCol - 1)
	
	elif Input.is_action_just_pressed("caret_right"):
		codeEdit.deselect()
		var currentCol = codeEdit.get_caret_column()
		codeEdit.set_caret_column(currentCol + 1)
	
	elif Input.is_action_just_pressed("caret_up"):
		codeEdit.deselect()
		var currentLine = codeEdit.get_caret_line()
		codeEdit.set_caret_line(currentLine - 1)
	
	elif Input.is_action_just_pressed("caret_down"):
		codeEdit.deselect()
		var currentLine = codeEdit.get_caret_line()
		codeEdit.set_caret_line(currentLine + 1)
	
	
	if Input.is_action_just_pressed("help"):
		help.visible = not help.visible


## Helper Functions
func find_para_beginning(caretLine):
	var fileRead = FileAccess.open(filePath, FileAccess.READ)
	var lines = fileRead.get_as_text().split("\n")
	var retLineNum = 0
	
	for i in range(caretLine):
		if lines[i].strip_edges() == "":
			retLineNum = i + 1
	
	return retLineNum

func find_para_end(caretLine):
	var fileRead = FileAccess.open(filePath, FileAccess.READ)
	var lines = fileRead.get_as_text().split("\n")
	
	for i in range(caretLine, lines.size()):
		if lines[i].strip_edges() == "":
			return i - 1
	
	return lines.size() - 1
