extends Control

@onready var fileDialog = $FileDialog
@onready var richLabel = $BoxContainer/TopContainer/RichTextLabel
@onready var codeEdit = $BoxContainer/SplitContainer/CodeEdit
@onready var help = $CanvasLayer
@onready var shortcutShow = $CanvasLayer/ShortcutPanel/MarginContainer/ShortcutShow
@onready var inputController = $InputController

var filePath = ""
var configPath = "user://azria_editor.conf"
var config : Dictionary
var showHelp : bool

func _ready() -> void:
	if FileAccess.file_exists(configPath):
		var confFile = FileAccess.open(configPath, FileAccess.READ)
		var json = JSON.new()
		var parseResult = json.parse(confFile.get_as_text())
		if parseResult == OK:
			config = json.data
			showHelp = config["OpenShortcutOnStartup"]
			shortcutShow.button_pressed = showHelp
			help.visible = !showHelp
		else:
			print("ERR")
	
	fileDialog.visible = true
	inputController.init()

func _on_file_dialog_file_selected(path: String) -> void:
	var fileRead = FileAccess.open(path, FileAccess.READ)
	codeEdit.text = fileRead.get_as_text()
	fileRead.close()
	richLabel.text = "[center]%s[/center]" % path
	filePath = path
	
	read_proglang(filePath.split(".")[1])

func _on_close_pressed() -> void:
	get_tree().quit()

# string.indent()?
func _process(_delta: float) -> void:
	inputController.process_input()


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

func save_config():
	var confFile = FileAccess.open(configPath, FileAccess.WRITE)
	if confFile != null:
		var jsonString = JSON.stringify({
			"OpenShortcutOnStartup": showHelp,
		}, "\t")
		confFile.store_line(jsonString)
		confFile.close()
	else:
		richLabel.text = "[center]%s[/center]" % FileAccess.get_open_error()

func read_proglang(ftype):
	if ftype == "c":
		var langFile = FileAccess.open("res://progLangs/%s.lang" % ftype, FileAccess.READ)
		var keywords : Array
		var commentDelim : Array
		var import : Array
		
		var json = JSON.new()
		var parseResult = json.parse(langFile.get_as_text())
		if parseResult == OK:
			var lang = json.data
			commentDelim = lang["comment"]
			keywords = lang["keywords"]
		else:
			push_error(json.get_error_message())
		
		#for item in commentDelim:
			#var key = str(item[0]) + " " + str(item[1])
			#codeEdit.syntax_highlighter.color_regions[item] = Color(Color.RED)
			#print(codeEdit.syntax_highlighter.color_regions)
		
		for item in keywords:
			codeEdit.syntax_highlighter.keyword_colors[item] = Color("#ff8ccc")

func _on_shortcut_default_show_toggled(toggled_on: bool) -> void:
	# only allows this to be saved
	#var confFile = FileAccess.open(configPath, FileAccess.WRITE)
	#if confFile != null:
		#var jsonString = JSON.stringify({"OpenShortcutOnStartup": toggled_on})
		#confFile.store_line(jsonString)
		#confFile.close()
	#else:
		#richLabel.text = "[center]%s[/center]" % FileAccess.get_open_error()
	showHelp = toggled_on
	save_config()

func _on_timer_timeout() -> void:
	richLabel.text = "[center]%s[/center]" % filePath
