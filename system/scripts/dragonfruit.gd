@tool
extends Control

"""
Dragonfruit Code Editor Wallpaper Plugin
Author: @kreaytore
Created: December 1st, 2024
"""

#region Filepath Vars
const SAVED_WP_DATA_FILE_PATH: String = "res://addons/Dragonfruit/system/saved_settings/"
const SAVED_WP_DATA_FILE_NAME: String = "saved_dragonfruit_settings.tres"
const SINGLE_BG_FILE_PATH: String = "res://addons/Dragonfruit/user_custom_bg_theme/"
const SINGLE_BG_FILE_NAME: String = "dragonfruit_bg_theme.tres"
const SLIDESHOW_BG_FILE_PATH: String = "res://addons/Dragonfruit/user_slideshow_images/"
const VIDEO_BG_FILE_PATH: String = "res://addons/Dragonfruit/user_video_bg/"
var saved_wp_data_resource: DragonfruitSettings = null
var local_options_for_saving: Dictionary = {}

# Banner
@onready var df_banner: TextureRect = $Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/DF_Banner
const BANNER: CompressedTexture2D = preload("res://addons/Dragonfruit/system/tool_theme/banner.jpg")
#endregion

#region General Vars
@onready var bg_mode_dropdown: OptionButton = $Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/BGModeHbox/BGModeDropdown
# Mode Choice
enum BGModes {
	SINGLE_BG,
	SLIDESHOW,
	VIDEO
}
var current_bg_mode: BGModes = BGModes.SINGLE_BG

# Theme
var custom_ce_theme: Theme = null
var custom_ce_stylebox_img_texture: StyleBoxTexture = null

# Autostart
@onready var autostart_check_box: CheckBox = $Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/AutoStartHbox/AutostartCheckBox
@onready var load_timer: Timer = $LoadTimer

var autostart_vid_slides: bool = true
#endregion

#region Video Vars
const DRAGONFRUIT_USER_VIDEO_SCENE: PackedScene = preload("res://addons/Dragonfruit/system/scenes/dragonfruit_user_video_scene.tscn")
@onready var use_method_dropdown: OptionButton = $Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/VideoUseBox/UseMethodDropdown
@onready var video_line_edit: LineEdit = $Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/VideoFileBox/VideoLineEdit
@onready var reset_deci_button: Button = $Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/VideoAudioBox/ResetDeciButton
@onready var db_spin_box: SpinBox = $Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/VideoAudioBox/db_SpinBox
@onready var mute_button: Button = $Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/VideoMuteBox/MuteButton
@onready var play_vid_button: Button = $Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/VideoControlBox/PlayVidButton
@onready var pause_vid_button: Button = $Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/VideoControlBox/PauseVidButton

var local_user_video_path: String = ""
var current_code_editor_base: Control = null
var switch_script_change: bool = false
var script_editor: ScriptEditor = null

enum VidFolderOrVidFile {
	FOLDER,
	CUSTOM_PATH
}
# Audio
var current_vid_mode: VidFolderOrVidFile = VidFolderOrVidFile.FOLDER
var video_player_for_buttons: VideoStreamPlayer = null
const DEFAULT_VID_VOLUME: float = -25.0
var last_vid_script_path: String = ""

@onready var vid_bus_dropdown: OptionButton = $Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/VideoBusHbox/VidBusDropdown
var project_buses: Array[String] = []
var current_selected_bus: String = "Master"
#endregion

#region Slideshow Vars
@onready var switch_timer_dropdown: OptionButton = $Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/SlideshowTimeHbox/SwitchTimerDropdown
enum SlideshowTimes {
	ONE_MINUTE = 60,
	FIVE_MINUTES = 300,
	TEN_MINUTES = 600,
	FIFTEEN_MINUTES = 900,
	THIRTY_MINUTES = 1800,
	FOURTYFIVE_MINUTES = 2700,
	ONE_HOUR = 3600,
	TWO_HOURS = 7200,
	THREE_HOURS = 10800
}
var current_slideshow_change_time: int = SlideshowTimes.TEN_MINUTES

var slideshow_files: Array[String] = []
var slideshow_is_running: bool = false
var do_first_slideshow_print: bool = true
@onready var image_change_timer: Timer = $Image_Change_Timer
@onready var time_label: RichTextLabel = $"Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/SlideshowTimeActualHbox/Time Label"
const DEFAULT_SLIDESHOW_TIME_TEXT: String = "[color=ff0054]---[/color]s until next change."
#endregion

#region Single Image Vars
@onready var addon_resource_picker: AddonResourcePicker = $"Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Img Hbox3/AddonResourcePicker"
var ce_bg_img: CompressedTexture2D = null
#endregion

#region Modulate Color Vars
@onready var color_picker_button: ColorPickerButton = $"Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Modulate Hbox/ColorPickerButton"
const DEFAULT_MODULATE_COLOR: Color = Color(0.137255, 0.137255, 0.137255, 1) # Hex Code "#222222"
@onready var custom_modulate_color: Color = DEFAULT_MODULATE_COLOR
#endregion

#region Axis Stretch Vars
@onready var h_axis_option: OptionButton = $"Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Axis Stretch Hbox/H Axis Option"
@onready var v_axis_option: OptionButton = $"Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Axis Stretch Hbox2/V Axis Option"
enum StretchModes {
	STRETCH,
	TILE,
	TILEFIT
}
var h_axis_mode = StretchModes.STRETCH
var v_axis_mode = StretchModes.STRETCH
#endregion

#region End Vars
@onready var clear_button: Button = $Panel/MarginContainer/VBoxContainer/Clear_Button
@onready var apply_button: Button = $Panel/MarginContainer/VBoxContainer/Apply_Button
#endregion

#region Utility/Start Funcs
func _ready() -> void:
	df_banner.set_texture(BANNER)

func _on_load_timer_timeout() -> void:
	"""
		If you're reading this, I bet you're wondering:
			"Why didn't he just use _ready()? Why is the initialization being
			done after a timer timeouts after 2 seconds?"
		It's because the Engine is shit and loads this script before the
		code editor loads. So it tries to get the code editor with the script
		while it doesn't exist yet. So I'm forcing a pause so this error goes
		away. It's annoying.
		The Engine isn't shit btw, I like it. It's just 3AM and I'm tired.
	"""
	
	init_custom_files()
	get_audio_buses()
	
	# This is for video script switching
	script_editor = EditorInterface.get_script_editor()
	script_editor.editor_script_changed.connect(script_editor_changed)
	
	get_saved_wp_data()

func _process(_delta: float) -> void:
	if slideshow_is_running:
		var time_left_rounded: int = int(floor(image_change_timer.get_time_left()))
		time_label.text = "[color=ff0054]%s[/color]s until next change." % time_left_rounded
	else:
		if time_label.text != DEFAULT_SLIDESHOW_TIME_TEXT:
			time_label.text = DEFAULT_SLIDESHOW_TIME_TEXT
	
	if autostart_check_box.is_pressed():
		if autostart_check_box.get_text() != "Autostart ON":
			autostart_check_box.set_text("Autostart ON")
	else:
		if autostart_check_box.get_text() != "Autostart OFF":
			autostart_check_box.set_text("Autostart OFF")
	
	if video_player_for_buttons != null:
		if vid_bus_dropdown.is_disabled():
			vid_bus_dropdown.set_disabled(false)
		if mute_button.is_disabled():
			mute_button.set_disabled(false)
		if play_vid_button.is_disabled():
			play_vid_button.set_disabled(false)
		if pause_vid_button.is_disabled():
			pause_vid_button.set_disabled(false)
		if reset_deci_button.is_disabled():
			reset_deci_button.set_disabled(false)
		if not db_spin_box.is_editable():
			db_spin_box.set_editable(true)
	else:
		if not vid_bus_dropdown.is_disabled():
			vid_bus_dropdown.set_disabled(true)
		if not mute_button.is_disabled():
			mute_button.set_disabled(true)
		if not play_vid_button.is_disabled():
			play_vid_button.set_disabled(true)
		if not pause_vid_button.is_disabled():
			pause_vid_button.set_disabled(true)
		if not reset_deci_button.is_disabled():
			reset_deci_button.set_disabled(true)
		if db_spin_box.is_editable():
			db_spin_box.set_editable(false)

func init_custom_files() -> void:
	var filesystem_changed: bool = false
	
	if not DirAccess.dir_exists_absolute(SINGLE_BG_FILE_PATH):
		DirAccess.make_dir_absolute(SINGLE_BG_FILE_PATH)
		filesystem_changed = true
	
	if not DirAccess.dir_exists_absolute(SLIDESHOW_BG_FILE_PATH):
		DirAccess.make_dir_absolute(SLIDESHOW_BG_FILE_PATH)
		filesystem_changed = true
	
	if not DirAccess.dir_exists_absolute(VIDEO_BG_FILE_PATH):
		DirAccess.make_dir_absolute(VIDEO_BG_FILE_PATH)
		filesystem_changed = true
		
	if not DirAccess.dir_exists_absolute(SAVED_WP_DATA_FILE_PATH):
		DirAccess.make_dir_absolute(SAVED_WP_DATA_FILE_PATH)
		filesystem_changed = true
	
	if filesystem_changed:
		scan_filesystem()

func script_editor_changed(script: Script) -> void:
	if current_code_editor_base != null:
		var script_path: String
		if script.get_path() != null and script.get_path() != "":
			script_path = script.get_path()
			if script_path.get_extension() == "gd": # Prevents non-godot files from causing issues
				if script_path != last_vid_script_path:
					"""
						This is very important because it prevents multiple video instances from
						existing.
					"""
					for child: Node in current_code_editor_base.get_children():
						child.queue_free()
					
					current_code_editor_base = null
					switch_script_change = true
					last_vid_script_path = script_path
					
					_init_bg_vid()

func scan_filesystem() -> void:
	if not EditorInterface.get_resource_filesystem().is_scanning():
		EditorInterface.get_resource_filesystem().scan()

func _on_autostart_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		autostart_vid_slides = true
	else:
		autostart_vid_slides = false
	
	if saved_wp_data_resource != null:
		saved_wp_data_resource.autostart_slides_vid = autostart_vid_slides
		save_wp_data()
#endregion

#region Single Image/General Funcs
func _on_addon_resource_picker_resource_changed(resource: Resource) -> void:
	ce_bg_img = resource

func create_custom_theme(mode: String = "image", backround_image_to_set: CompressedTexture2D = null) -> void:
	match mode:
		"image":
			if backround_image_to_set != null:
				custom_ce_theme = Theme.new()
				custom_ce_theme.add_type("CodeEdit")
				
				custom_ce_stylebox_img_texture = StyleBoxTexture.new()
				custom_ce_stylebox_img_texture.texture = backround_image_to_set
				
				custom_ce_stylebox_img_texture.set_modulate(custom_modulate_color)
				
				custom_ce_stylebox_img_texture.set_h_axis_stretch_mode(h_axis_mode)
				custom_ce_stylebox_img_texture.set_v_axis_stretch_mode(v_axis_mode)
				
				custom_ce_theme.set_stylebox("normal", "CodeEdit", custom_ce_stylebox_img_texture)
				
				## Save Theme
				var new_single_bg_filename: String = str(randi() % 9999999999 + 1) + "_" + SINGLE_BG_FILE_NAME
				
				clear_custom_theme_folder()
				
				ResourceSaver.save(custom_ce_theme, SINGLE_BG_FILE_PATH + new_single_bg_filename)
				
				scan_filesystem()
				
				var custom_editor_theme_setting: EditorSettings = EditorInterface.get_editor_settings()
				custom_editor_theme_setting.set_setting("interface/theme/custom_theme", SINGLE_BG_FILE_PATH + new_single_bg_filename)
				
				# End
				if current_bg_mode == BGModes.SINGLE_BG:
					print_rich("[color=ff0054][wave]Dragonfruit: Background Successfully Changed![/wave][/color]")
				elif current_bg_mode == BGModes.SLIDESHOW:
					if do_first_slideshow_print:
						do_first_slideshow_print = false
						print_rich("[color=ff0054][wave]Dragonfruit: Slideshow Successfully Started! [/wave](Expect a small stutter.)[/color]")
			else:
				push_warning("Tried to create a custom BG theme but there is no bg image to be set.")
				return
			
		"video":
			if not switch_script_change:
				custom_ce_theme = Theme.new()
				custom_ce_theme.add_type("CodeEdit")
				
				var empty_texture: StyleBoxEmpty = StyleBoxEmpty.new()
				
				custom_ce_theme.set_stylebox("normal", "CodeEdit", empty_texture)
				
				var new_single_bg_filename: String = str(randi() % 9999999999 + 1) + "_" + SINGLE_BG_FILE_NAME
				
				clear_custom_theme_folder()
				
				ResourceSaver.save(custom_ce_theme, SINGLE_BG_FILE_PATH + new_single_bg_filename)
				
				scan_filesystem()
				
				var custom_editor_theme_setting: EditorSettings = EditorInterface.get_editor_settings()
				custom_editor_theme_setting.set_setting("interface/theme/custom_theme", SINGLE_BG_FILE_PATH + new_single_bg_filename)

func _on_bg_mode_dropdown_item_selected(index: int) -> void:
	match index:
		0:
			current_bg_mode = BGModes.SINGLE_BG
		1:
			current_bg_mode = BGModes.SLIDESHOW
		2:
			current_bg_mode = BGModes.VIDEO
	
	if saved_wp_data_resource != null:
		saved_wp_data_resource.saved_bg_mode = current_bg_mode
		save_wp_data()
#endregion

#region Slideshow Funcs
func handle_slideshow_new_image_decider() -> void:
	var random_files_name: String = slideshow_files.pick_random()
	
	var random_files_filepath: String = SLIDESHOW_BG_FILE_PATH + random_files_name
	
	if not FileAccess.file_exists(random_files_filepath):
		slideshow_is_running = false
		image_change_timer.stop()
		push_warning("Dragonfruit couldn't do the Slideshow. \"" + random_files_filepath + "\" Could not be found in the folder.")
		return
	
	var random_files_image: Resource = load(random_files_filepath)
	
	if random_files_image is not CompressedTexture2D:
		slideshow_is_running = false
		image_change_timer.stop()
		push_warning("Dragonfruit couldn't do the Slideshow. \"" + random_files_filepath + "\" could not be converted to a CompressedTexture2D despite having an image extension. Therefore it is probably not a valid image. Please remove the file and restart the slideshow.")
		return
	
	slideshow_is_running = true
	image_change_timer.set_wait_time(current_slideshow_change_time)
	image_change_timer.start()
	
	create_custom_theme("image", random_files_image)

func _on_image_change_timer_timeout() -> void:
	handle_slideshow_new_image_decider()

func _on_switch_timer_dropdown_item_selected(index: int) -> void:
	match index:
		0:
			current_slideshow_change_time = SlideshowTimes.ONE_MINUTE
		1:
			current_slideshow_change_time = SlideshowTimes.FIVE_MINUTES
		2:
			current_slideshow_change_time = SlideshowTimes.TEN_MINUTES
		3:
			current_slideshow_change_time = SlideshowTimes.FIFTEEN_MINUTES
		4:
			current_slideshow_change_time = SlideshowTimes.THIRTY_MINUTES
		5:
			current_slideshow_change_time = SlideshowTimes.FOURTYFIVE_MINUTES
		6:
			current_slideshow_change_time = SlideshowTimes.ONE_HOUR
		7:
			current_slideshow_change_time = SlideshowTimes.TWO_HOURS
		8:
			current_slideshow_change_time = SlideshowTimes.THREE_HOURS
		_:
			current_slideshow_change_time = SlideshowTimes.FIVE_MINUTES

	if saved_wp_data_resource != null:
		var slideshow_time_index: int = 0
		for value in SlideshowTimes.values():
			if value == current_slideshow_change_time:
				break
			else:
				slideshow_time_index += 1
		saved_wp_data_resource.saved_slideshow_switch_time = slideshow_time_index
		save_wp_data()
#endregion

#region Modulate Color Funcs
func _on_color_picker_button_color_changed(color: Color) -> void:
	custom_modulate_color = color
	
	if saved_wp_data_resource != null:
		saved_wp_data_resource.saved_modulate_color = color
		save_wp_data()

func _on_reset_color_button_pressed() -> void:
	color_picker_button.set_pick_color(DEFAULT_MODULATE_COLOR)
	custom_modulate_color = DEFAULT_MODULATE_COLOR
	
	if saved_wp_data_resource != null:
		saved_wp_data_resource.saved_modulate_color = DEFAULT_MODULATE_COLOR
		save_wp_data()
#endregion

#region Axis Stretch Funcs
func _on_h_axis_option_item_selected(index: int) -> void:
	match index:
		0:
			h_axis_mode = StretchModes.STRETCH
		1:
			h_axis_mode = StretchModes.TILE
		2:
			h_axis_mode = StretchModes.TILEFIT
	
	if saved_wp_data_resource != null:
		saved_wp_data_resource.saved_h_axis_stretch = h_axis_mode
		save_wp_data()

func _on_v_axis_option_item_selected(index: int) -> void:
	match index:
		0:
			v_axis_mode = StretchModes.STRETCH
		1:
			v_axis_mode = StretchModes.TILE
		2:
			v_axis_mode = StretchModes.TILEFIT
	
	if saved_wp_data_resource != null:
		saved_wp_data_resource.saved_v_axis_stretch = v_axis_mode
		save_wp_data()
#endregion

#region Video Funcs
func _init_bg_vid() -> void:
	match current_vid_mode:
		VidFolderOrVidFile.FOLDER:
			if DirAccess.dir_exists_absolute(VIDEO_BG_FILE_PATH):
				if not DirAccess.get_files_at(VIDEO_BG_FILE_PATH).is_empty():
					var vid_found: bool = false
					
					for file in DirAccess.get_files_at(VIDEO_BG_FILE_PATH):
						var file_extension: String = file.get_extension()
						
						if file_extension == "ogv" or file_extension == "ogg":
							local_user_video_path = VIDEO_BG_FILE_PATH + file
							vid_found = true
							break
					
					if vid_found == false:
						push_warning("Dragonfruit couldn't apply Video BG. \"" + VIDEO_BG_FILE_PATH + "\" is not empty but there are no compatible files.")
						return
				
				else:
					push_warning("Dragonfruit couldn't apply Video BG. \"" + VIDEO_BG_FILE_PATH + "\" is empty.")
					return
				
			else:
				push_warning("Dragonfruit couldn't apply Video BG. \"" + VIDEO_BG_FILE_PATH + "\" does mot exist.")
				return
		
		VidFolderOrVidFile.CUSTOM_PATH:
			if video_line_edit.get_text() != "" and video_line_edit.get_text() != null:
				local_user_video_path = video_line_edit.get_text()
				
				if saved_wp_data_resource != null:
					saved_wp_data_resource.saved_custom_video_path = local_user_video_path
					save_wp_data()
				
			else:
				push_warning("Dragonfruit couldn't apply Video BG. Custom Path is selected but no custom path has been set.")
				return
		
		_:
			push_warning("Dragonfruit couldn't apply Video BG. No Method Selected?")
			return
	
	if local_user_video_path == "" or local_user_video_path == null:
		push_warning("Dragonfruit couldn't apply Video BG. Local vid file is null.")
		return
	elif not FileAccess.file_exists(local_user_video_path):
		push_warning("Dragonfruit couldn't apply Video BG. Local vid file's path does not exist.")
		return
	
	var user_vid_check: Resource = load(local_user_video_path)
	if user_vid_check is not VideoStreamTheora:
		push_warning("Dragonfruit couldn't apply Video BG. Video file selected but it is not of type VideoStreamTheora.")
		return
	
	get_audio_buses()
	create_custom_theme("video")
	
	current_code_editor_base = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
	
	var video_player_scene: Control = DRAGONFRUIT_USER_VIDEO_SCENE.instantiate()
	var video_stream_player: VideoStreamPlayer = video_player_scene.get_node("Video_MC/VideoStreamPlayer")
	
	var video_stream: VideoStreamTheora = VideoStreamTheora.new()
	
	video_stream.set_file(local_user_video_path)
	
	video_stream_player.set_stream(video_stream)
	
	if saved_wp_data_resource != null:
		video_stream_player.volume_db = saved_wp_data_resource.saved_video_volume
	else:
		video_stream_player.volume_db = DEFAULT_VID_VOLUME
	
	if saved_wp_data_resource != null:
		if project_buses.has(saved_wp_data_resource.saved_bus):
			video_stream_player.set_bus(saved_wp_data_resource.saved_bus)
			vid_bus_dropdown._select_int(project_buses.find(saved_wp_data_resource.saved_bus))
		else:
			video_stream_player.set_bus("Master")
			vid_bus_dropdown._select_int(0)
	else:
		video_stream_player.set_bus("Master")
		vid_bus_dropdown._select_int(0)
	
	if current_code_editor_base.get_children().is_empty():
		current_code_editor_base.add_child(video_player_scene)
		current_code_editor_base.get_node("dragonfruit_user_video_scene/Video_MC/VideoStreamPlayer").play()
		video_player_for_buttons = current_code_editor_base.get_node("dragonfruit_user_video_scene/Video_MC/VideoStreamPlayer")
	else:
		current_code_editor_base.get_node("dragonfruit_user_video_scene/Video_MC/VideoStreamPlayer").play()
		video_player_for_buttons = current_code_editor_base.get_node("dragonfruit_user_video_scene/Video_MC/VideoStreamPlayer")
	
	## End
	if not switch_script_change:
		print_rich("[color=ff0054][wave]Dragonfruit: Video Successfully Played![/wave][/color]")

func _on_use_method_dropdown_item_selected(index: int) -> void:
	match index:
		0:
			current_vid_mode = VidFolderOrVidFile.FOLDER
		1:
			current_vid_mode = VidFolderOrVidFile.CUSTOM_PATH
			
	if saved_wp_data_resource != null:
		saved_wp_data_resource.saved_vid_method = current_vid_mode
		save_wp_data()

func _on_vid_bus_dropdown_item_selected(index: int) -> void:
	if video_player_for_buttons != null:
		if not project_buses.is_empty():
			current_selected_bus = project_buses[index]
			video_player_for_buttons.set_bus(current_selected_bus)
			
			if saved_wp_data_resource != null:
				saved_wp_data_resource.saved_bus = current_selected_bus
				save_wp_data()

func get_audio_buses() -> void:
	vid_bus_dropdown.clear()
	project_buses.clear()
	
	for bus in range(AudioServer.get_bus_count()):
		var bus_name: String = AudioServer.get_bus_name(bus)
		project_buses.append(bus_name)
	
	var index: int = 0
	for bus: String in project_buses:
		vid_bus_dropdown.add_item(bus, index)
		index += 1

func _on_db_spin_box_value_changed(value: float) -> void:
	if video_player_for_buttons != null:
		video_player_for_buttons.set_volume_db(value)
		
		mute_button.set_pressed_no_signal(false)
		mute_button.text = "Mute Video"
		
		if saved_wp_data_resource != null:
			saved_wp_data_resource.saved_video_volume = value
			save_wp_data()

func _on_reset_deci_button_pressed() -> void:
	if video_player_for_buttons != null:
		db_spin_box.value = DEFAULT_VID_VOLUME
		video_player_for_buttons.set_volume_db(DEFAULT_VID_VOLUME)
		
		mute_button.set_pressed_no_signal(false)
		mute_button.text = "Mute Video"
		
		if saved_wp_data_resource != null:
			saved_wp_data_resource.saved_video_volume = DEFAULT_VID_VOLUME
			save_wp_data()

func _on_mute_button_toggled(toggled_on: bool) -> void:
	if video_player_for_buttons != null:
		if toggled_on:
			video_player_for_buttons.set_volume_db(-80)
			mute_button.text = "Unmute Video"
			
			if saved_wp_data_resource != null:
				saved_wp_data_resource.saved_video_volume = -80
				save_wp_data()
			
		else:
			video_player_for_buttons.set_volume_db(db_spin_box.value)
			mute_button.text = "Mute Video"
			
			if saved_wp_data_resource != null:
				saved_wp_data_resource.saved_video_volume = db_spin_box.value
				save_wp_data()

func _on_play_vid_button_pressed() -> void:
	if video_player_for_buttons != null:
		if video_player_for_buttons.is_paused():
			video_player_for_buttons.set_paused(false)

func _on_pause_vid_button_pressed() -> void:
	if video_player_for_buttons != null:
		video_player_for_buttons.set_paused(true)
#endregion

#region Finish Funcs
func _on_apply_button_pressed() -> void:
	init_custom_files()
	
	slideshow_is_running = false
	image_change_timer.stop()
	
	match current_bg_mode:
		BGModes.SINGLE_BG:
			if addon_resource_picker.get_edited_resource() != null:
				ce_bg_img = addon_resource_picker.get_edited_resource()
				
				create_custom_theme("image", ce_bg_img)
			else:
				push_warning("Dragonfruit couldn't change the BG to a Single Image. No \"Single Image\" is set.")
				return
		
		BGModes.SLIDESHOW:
			if DirAccess.dir_exists_absolute(SLIDESHOW_BG_FILE_PATH):
				if not DirAccess.get_files_at(SLIDESHOW_BG_FILE_PATH).is_empty():
					for image: String in DirAccess.get_files_at(SLIDESHOW_BG_FILE_PATH):
						var file_extension: String = image.get_extension()
						if file_extension == "png" or file_extension == "jpg" or \
								file_extension == "jpeg":
							slideshow_files.append(image)
					
					if slideshow_files.is_empty():
						push_warning("Dragonfruit couldn't do a Slideshow. \"" + SLIDESHOW_BG_FILE_PATH + "\" has no (Compatible) Images.")
						return
					
					do_first_slideshow_print = true
					handle_slideshow_new_image_decider()
				else:
					push_warning("Dragonfruit couldn't do a Slideshow. \"" + SLIDESHOW_BG_FILE_PATH + "\" has no Images.")
					return
			else:
				push_warning("Dragonfruit couldn't do a Slideshow. \"" + SLIDESHOW_BG_FILE_PATH + "\" does not exist.")
				return
		
		BGModes.VIDEO:
			_init_bg_vid()
		
		_:
			pass

func _on_clear_button_pressed() -> void:
	if addon_resource_picker.get_edited_resource() != null:
		addon_resource_picker.set_edited_resource(null)
	
	var slideshow_was_running: bool
	if slideshow_is_running:
		slideshow_is_running = false
		image_change_timer.stop()
		slideshow_was_running = true
		do_first_slideshow_print = true
	
	var custom_editor_theme_setting: EditorSettings = EditorInterface.get_editor_settings()
	if custom_editor_theme_setting.get_setting("interface/theme/custom_theme") != "" and \
			custom_editor_theme_setting.get_setting("interface/theme/custom_theme") != null:
		custom_editor_theme_setting.set_setting("interface/theme/custom_theme", "")
	
	clear_custom_theme_folder()
	
	if DirAccess.dir_exists_absolute(SAVED_WP_DATA_FILE_PATH):
		for file: String in DirAccess.get_files_at(SAVED_WP_DATA_FILE_PATH):
			DirAccess.remove_absolute(SAVED_WP_DATA_FILE_PATH + file)
		
		DirAccess.remove_absolute(SAVED_WP_DATA_FILE_PATH)
		
		init_custom_files()
		get_saved_wp_data()
	
	print_rich("[color=yellow]Dragonfruit's Background Image and Saved Theme Successfully Removed.[/color]")
	if slideshow_was_running:
		print_rich("[color=yellow]Dragonfruit's Slideshow has been stopped.[/color]")

func clear_custom_theme_folder() -> void:
	init_custom_files()
	
	for custom_theme_file: String in DirAccess.get_files_at(SINGLE_BG_FILE_PATH):
		DirAccess.remove_absolute(SINGLE_BG_FILE_PATH + custom_theme_file)
	
	var custom_editor_theme_setting: EditorSettings = EditorInterface.get_editor_settings()
	custom_editor_theme_setting.set_setting("interface/theme/custom_theme", "")
	
	current_code_editor_base = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
	if not current_code_editor_base.get_children().is_empty():
		for child: Node in current_code_editor_base.get_children():
			child.queue_free()
	
	current_code_editor_base = null
	video_player_for_buttons = null
	switch_script_change = false
	last_vid_script_path = ""
	
	scan_filesystem()
#endregion

#region Save Load Funcs
func get_saved_wp_data() -> void:
	if FileAccess.file_exists(SAVED_WP_DATA_FILE_PATH + SAVED_WP_DATA_FILE_NAME):
		load_wp_data()
	else:
		saved_wp_data_resource = DragonfruitSettings.new()
		save_wp_data()
	
	scan_filesystem()

func save_wp_data() -> void:
	ResourceSaver.save(saved_wp_data_resource, SAVED_WP_DATA_FILE_PATH + SAVED_WP_DATA_FILE_NAME)

func load_wp_data() -> void:
	saved_wp_data_resource = ResourceLoader.load(SAVED_WP_DATA_FILE_PATH + SAVED_WP_DATA_FILE_NAME)
	
	bg_mode_dropdown._select_int(saved_wp_data_resource.saved_bg_mode)
	bg_mode_dropdown.emit_signal("item_selected", saved_wp_data_resource.saved_bg_mode)
	
	autostart_check_box.set_pressed(saved_wp_data_resource.autostart_slides_vid)
	
	switch_timer_dropdown._select_int(saved_wp_data_resource.saved_slideshow_switch_time)
	switch_timer_dropdown.emit_signal("item_selected", saved_wp_data_resource.saved_slideshow_switch_time)
	
	use_method_dropdown._select_int(saved_wp_data_resource.saved_vid_method)
	use_method_dropdown.emit_signal("item_selected", saved_wp_data_resource.saved_vid_method)
	video_line_edit.set_text(saved_wp_data_resource.saved_custom_video_path)
	
	var bus_index: int = project_buses.find(saved_wp_data_resource.saved_bus)
	if bus_index == -1:
		bus_index = 0
	vid_bus_dropdown._select_int(bus_index)
	vid_bus_dropdown.emit_signal("item_selected", bus_index)
	# Bus is being set in the init_vid()
	
	db_spin_box.set_value(saved_wp_data_resource.saved_video_volume)
	# Volume is being set in the init_vid()
	
	color_picker_button.set_pick_color(saved_wp_data_resource.saved_modulate_color)
	custom_modulate_color = saved_wp_data_resource.saved_modulate_color
	
	h_axis_option._select_int(saved_wp_data_resource.saved_h_axis_stretch)
	h_axis_option.emit_signal("item_selected", saved_wp_data_resource.saved_h_axis_stretch)
	v_axis_option._select_int(saved_wp_data_resource.saved_v_axis_stretch)
	v_axis_option.emit_signal("item_selected", saved_wp_data_resource.saved_v_axis_stretch)
	
	if autostart_vid_slides and current_bg_mode != BGModes.SINGLE_BG and current_bg_mode != null:
		apply_button.emit_signal("pressed")
#endregion
