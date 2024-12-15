extends Control

@onready var fileDialog = $FileDialog
@onready var richLabel = $BoxContainer/HBoxContainer/RichTextLabel
@onready var codeEdit = $BoxContainer/CodeEdit
@onready var timer = $SaveTimer
@onready var help = $CanvasLayer
@onready var shortcutShow = $CanvasLayer/ShortcutPanel/MarginContainer/ShortcutShow

var filePath = ""

func _ready() -> void:
	if FileAccess.file_exists("user://azria_editor.conf"):
		var confFile = FileAccess.open("user://azria_editor.conf", FileAccess.READ)
		var json = JSON.new()
		var parseResult = json.parse(confFile.get_line())
		if parseResult == OK:
			var showHelp : bool = json.data["OpenShortcutOnStartup"]
			shortcutShow.button_pressed = showHelp
			help.visible = !showHelp
	
	fileDialog.visible = true

func _on_file_dialog_file_selected(path: String) -> void:
	var fileRead = FileAccess.open(path, FileAccess.READ)
	richLabel.text = "[center]%s[/center]" % path
	codeEdit.text = fileRead.get_as_text()
	filePath = path
	fileRead.close()

func _on_close_pressed() -> void:
	get_tree().quit()

# string.indent()?
func _process(_delta: float) -> void:
	if Input.is_action_pressed("block"):
		codeEdit.editable = false
	elif Input.is_action_just_released("block"):
		codeEdit.editable = true
	
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
		codeEdit.set_selection_mode(TextEdit.SELECTION_MODE_SHIFT)
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
		codeEdit.set_selection_mode(TextEdit.SELECTION_MODE_SHIFT)
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

func _on_shortcut_default_show_toggled(toggled_on: bool) -> void:
	# only allows this to be saved
	var confFile = FileAccess.open("user://azria_editor.conf", FileAccess.WRITE)
	if confFile != null:
		var jsonString = JSON.stringify({"OpenShortcutOnStartup": toggled_on})
		confFile.store_line(jsonString)
		confFile.close()
	else:
		print(FileAccess.get_open_error())

func _on_timer_timeout() -> void:
	richLabel.text = "[center]%s[/center]" % filePath
