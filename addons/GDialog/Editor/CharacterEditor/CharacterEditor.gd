tool
extends ScrollContainer

onready var node_new_portrait_button = $HBoxContainer/Container/ScrollContainer/VBoxContainer/HBoxContainer/Button
onready var node_import_from_folder_button = $HBoxContainer/Container/ScrollContainer/VBoxContainer/HBoxContainer/ImportFromFolder
onready var node_display_name_checkbox = $HBoxContainer/Container/Name/CheckBox
onready var node_nickname_checkbox = $HBoxContainer/Container/Name/CheckBox2
onready var node_name = $HBoxContainer/Container/Name/LineEdit
onready var node_color = $HBoxContainer/Container/Color/ColorPickerButton
onready var node_file = $HBoxContainer/Container/FileName/LineEdit
onready var node_description = $HBoxContainer/Container/Description/TextEdit
onready var node_mirror_portraits_checkbox = $HBoxContainer/VBoxContainer/HBoxContainer/MirrorOption/MirrorPortraitsCheckBox
onready var node_displayName = $HBoxContainer/Container/DisplayName
onready var node_displayName_lineEdit = $HBoxContainer/Container/DisplayName/LineEdit
onready var node_displayNickname = $HBoxContainer/Container/DisplayNickname
onready var node_displayNickname_lineEdit = $HBoxContainer/Container/DisplayNickname/LineEdit
onready var node_portrait_preview = $HBoxContainer/VBoxContainer/Control/TextureRect
onready var node_image_label = $HBoxContainer/VBoxContainer/Control/Label
onready var node_scale = $HBoxContainer/VBoxContainer/HBoxContainer/Scale
onready var node_offset_x = $HBoxContainer/VBoxContainer/HBoxContainer/OffsetX
onready var node_offset_y = $HBoxContainer/VBoxContainer/HBoxContainer/OffsetY
onready var node_portraitList = $HBoxContainer/Container/ScrollContainer/VBoxContainer/PortraitList

var editor_reference
onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
var opened_character_data
var portrait_entry = load("res://addons/GDialog/Editor/CharacterEditor/PortraitEntry.tscn")

func _ready():
	node_new_portrait_button.connect('pressed', self, '_on_New_Portrait_Button_pressed')
	node_import_from_folder_button.connect('pressed', self, '_on_Import_Portrait_Folder_Button_pressed')
	node_display_name_checkbox.connect('toggled', self, '_on_display_name_toggled')
	node_nickname_checkbox.connect('toggled', self, '_on_nickname_toggled')
	node_name.connect('text_changed', self, '_on_name_changed')
	node_name.connect('focus_exited', self, '_update_name_on_tree')
	node_color.connect('color_changed', self, '_on_color_changed')
	
	var style = get('custom_styles/bg')
	style.set('bg_color', get_color("base_color", "Editor"))
	
	node_new_portrait_button.icon = get_icon("Add", "EditorIcons")
	node_import_from_folder_button.icon = get_icon("Folder", "EditorIcons")

func _on_display_name_toggled(button_pressed):
	node_displayName.visible = button_pressed

func _on_nickname_toggled(button_pressed):
	node_displayNickname.visible = button_pressed

func is_selected(file: String):
	return node_file.text == file

func _on_name_changed(value):
	save_character()

func _update_name_on_tree():
	var item = master_tree.get_selected()
	item.set_text(0, node_name.text)
	master_tree.build_characters(node_file.text)
	

func _input(event):
	if event is InputEventKey and event.pressed:
		if node_name.has_focus():
			if event.scancode == KEY_ENTER:
				node_name.release_focus()

func _on_color_changed(color):
	var item = master_tree.get_selected()
	item.set_icon_modulate(0, color)

func clear_character_editor():
	node_file.text = ""
	node_name.text = ""
	node_description.text = ""
	node_color.color = Color('#ffffff')
	node_mirror_portraits_checkbox.pressed = false
	node_display_name_checkbox.pressed = false
	node_nickname_checkbox.pressed = false
	node_displayName_lineEdit.text = ""
	node_displayNickname_lineEdit.text = ""
	node_scale.value = 100
	node_offset_x.value = 0
	node_offset_y.value = 0

	# Clearing portraits
	for p in node_portraitList.get_children():
		p.queue_free()
	node_portrait_preview.texture = null

# Character Creation
func create_character():
	var character_file = 'character-' + str(OS.get_unix_time()) + '.json'
	var character = {
		'color': '#ffffff',
		'id': character_file,
		'portraits': [],
		'mirror_portraits' :false
	}
	GDialog_Resources.set_character(character)
	character['metadata'] = {'file': character_file}
	return character

# Saving and Loading
func generate_character_data_to_save():
	var portraits = []
	for p in node_portraitList.get_children():
		var entry = {}
		entry['name'] = p.get_node("NameEdit").text
		entry['path'] = p.get_node("PathEdit").text
		portraits.append(entry)
	var info_to_save = {
		'id': node_file.text,
		'description': node_description.text,
		'color': '#' + node_color.color.to_html(),
		'mirror_portraits': node_mirror_portraits_checkbox.pressed,
		'portraits': portraits,
		'display_name_bool': node_display_name_checkbox.pressed,
		'display_name': node_displayName_lineEdit.text,
		'nickname_bool': node_nickname_checkbox.pressed,
		'nickname': node_displayNickname_lineEdit.text,
		'scale': node_scale.value,
		'offset_x': node_offset_x.value,
		'offset_y': node_offset_y.value,
	}
	# Adding name later for cases when no name is provided
	if node_name.text != "":
		info_to_save['name'] = node_name.text
	
	return info_to_save

func save_character():
	var info_to_save = generate_character_data_to_save()
	if info_to_save['id']:
		GDialog_Resources.set_character(info_to_save)
		opened_character_data = info_to_save

func load_character(name:String):
	clear_character_editor()
	
	var data = editor_reference.characters[name]
	
	opened_character_data = data

	node_name.text = name
	node_description.text = data.get('description', "")
	node_color.color = Color(data.get('color','#ffffffff'))
	node_display_name_checkbox.pressed = data.get('display_name_bool', false)
	node_displayName_lineEdit.text = data.get('display_name', "")
	node_scale.value = float(data.get('scale', 100))
	node_nickname_checkbox.pressed = data.get('nickname_bool', false)
	node_displayNickname_lineEdit.text = data.get('nickname', "")
	node_offset_x.value = data.get('offset_x', 0)
	node_offset_y.value = data.get('offset_y', 0)
	node_mirror_portraits_checkbox.pressed = data.get('mirror_portraits', false)
	node_portrait_preview.flip_h = data.get('mirror_portraits', false)

	# Portraits
	var default_portrait = create_portrait_entry()
	default_portrait.get_node('NameEdit').text = 'Default'
	default_portrait.get_node('NameEdit').editable = false
	if data.has('portraits'):
		for p in data['portraits']:
			if p['name'] == 'Default':
				default_portrait.get_node('PathEdit').text = p['path']
				default_portrait.update_preview(p['path'])
			else:
				create_portrait_entry(p['name'], p['path'])

# Portraits
func _on_New_Portrait_Button_pressed():
	create_portrait_entry("", "", true)

func create_portrait_entry(p_name = "", path = "", grab_focus = false):
	var p = portrait_entry.instance()
	p.editor_reference = editor_reference
	p.image_node = node_portrait_preview
	p.image_label = node_image_label
	var p_list = node_portraitList
	p_list.add_child(p)
	if p_name != "":
		p.get_node("NameEdit").text = p_name
	if path != "":
		p.get_node("PathEdit").text = path
	if grab_focus:
		p.get_node("NameEdit").grab_focus()
		p._on_ButtonSelect_pressed()
	return p

func _on_Import_Portrait_Folder_Button_pressed():
	editor_reference.godot_dialog("*", EditorFileDialog.MODE_OPEN_DIR)
	editor_reference.godot_dialog_connect(self, "_on_dir_selected", "dir_selected")

func _on_dir_selected(path, target):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var file_lower = file_name.to_lower()
				if '.svg' in file_lower or '.png' in file_lower:
					if not '.import' in file_lower:
						var final_name = path+ "/" + file_name
						create_portrait_entry(GDialog_Resources.get_filename_from_path(file_name), final_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func _on_MirrorPortraitsCheckBox_toggled(button_pressed):
	node_portrait_preview.flip_h = button_pressed
