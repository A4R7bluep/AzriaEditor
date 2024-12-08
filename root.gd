extends Control

@onready var fileDialog = $FileDialog
@onready var richLabel = $BoxContainer/HBoxContainer/RichTextLabel
@onready var codeEdit = $BoxContainer/CodeEdit
@onready var timer = $Timer
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
	if Input.is_action_just_pressed("file_save"):
		var fileWrite = FileAccess.open(filePath, FileAccess.WRITE)
		var currentCol = codeEdit.get_caret_column()
		var currentLine = codeEdit.get_caret_line()
		codeEdit.remove_text(currentLine, currentCol - 1, currentLine, currentCol)
		
		fileWrite.store_string(codeEdit.text)
		fileWrite.close()
		richLabel.text = "[center]%s - saved[/center]" % filePath
		timer.start(5)
	
	if Input.is_action_just_pressed("file_open"):
		var currentCol = codeEdit.get_caret_column()
		var currentLine = codeEdit.get_caret_line()
		codeEdit.remove_text(currentLine, max(currentCol - 1, 0), currentLine, currentCol)
		
		fileDialog.visible = true
	
	if Input.is_action_just_pressed("caret_left"):
		var currentCol = codeEdit.get_caret_column()
		var currentLine = codeEdit.get_caret_line()
		codeEdit.remove_text(currentLine, currentCol - 1, currentLine, currentCol)
		codeEdit.set_caret_column(currentCol - 2)
	
	if Input.is_action_just_pressed("caret_right"):
		var currentCol = codeEdit.get_caret_column()
		var currentLine = codeEdit.get_caret_line()
		codeEdit.remove_text(currentLine, currentCol - 1, currentLine, currentCol)
		codeEdit.set_caret_column(currentCol)
	
	if Input.is_action_just_pressed("caret_up"):
		var currentCol = codeEdit.get_caret_column()
		var currentLine = codeEdit.get_caret_line()
		codeEdit.remove_text(currentLine, max(currentCol - 1, 0), currentLine, currentCol)
		codeEdit.set_caret_line(currentLine - 1)
	
	if Input.is_action_just_pressed("caret_down"):
		var currentCol = codeEdit.get_caret_column()
		var currentLine = codeEdit.get_caret_line()
		codeEdit.remove_text(currentLine, currentCol - 1, currentLine, currentCol)
		codeEdit.set_caret_line(currentLine + 1)
	
	if Input.is_action_just_pressed("caret_beginning_line"):
		codeEdit.set_caret_column(0)
	
	if Input.is_action_just_pressed("caret_end_line"):
		var currentLine = codeEdit.get_caret_line()
		codeEdit.set_caret_column(len(codeEdit.get_line(currentLine)))
	
	if Input.is_action_just_pressed("caret_beginning_para"):
		var currentLine = codeEdit.get_caret_line()
		var begParaLine = find_para_beginning(currentLine)
		codeEdit.set_caret_line(begParaLine)
		codeEdit.set_caret_column(codeEdit.get_first_non_whitespace_column(begParaLine))
	
	if Input.is_action_just_pressed("caret_end_para"):
		var currentLine = codeEdit.get_caret_line()
		var endParaLine = find_para_end(currentLine)
		codeEdit.set_caret_line(endParaLine)
		codeEdit.set_caret_column(codeEdit.get_first_non_whitespace_column(endParaLine))
	
	if Input.is_action_just_pressed("help"):
		var currentCol = codeEdit.get_caret_column()
		var currentLine = codeEdit.get_caret_line()
		codeEdit.remove_text(currentLine, max(currentCol - 1, 0), currentLine, currentCol)
		
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
