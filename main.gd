extends Control

var SAVE_PATH := "res://data.dat"
var DAY_LENGTH := 86400
var SNAP_ANIMATION_TIME := 0.12
var NORMAL_SCALE := Vector2(1, 1)
var SELECTED_SCALE := Vector2(1.25, 1.25)
var TRACKER_SIZE := 98+16

var snap_tween: Tween
var selected_day: TextureProgressBar
var first_entry_date: int

@onready var tracker_scroll := $ScrollContainer
@onready var tracker_container := $ScrollContainer/HBoxContainer
@onready var water_amount_input := $ColorRect/SpinBox2
@onready var water_goal_input := $ColorRect/SpinBox
@onready var water_amount_label := $Label3
@onready var splash_label := $Label/Label

func _process(_delta: float) -> void:
	selected_day.scale = NORMAL_SCALE
	selected_day = tracker_container.get_child(2+tracker_scroll.scroll_horizontal/TRACKER_SIZE)
	selected_day.scale = SELECTED_SCALE
	water_amount_label.text = str(selected_day.water_amount) +"L / " + str(selected_day.water_goal) + "L"
	splash_label.text = "today's goal completed" if (get_today_tracker().water_amount >= get_today_tracker().water_goal) else "stay hydrated"

func _ready():
	if !FileAccess.file_exists(SAVE_PATH):
		create_save_file()
	load_state()
	var tracker_count = tracker_container.get_child_count()
	selected_day = tracker_container.get_child(tracker_count-2)
	tracker_scroll.gui_input.connect(_on_scroll_gui_input)
	await get_tree().process_frame
	tracker_scroll.scroll_horizontal = tracker_scroll.get_h_scroll_bar().max_value

func _on_scroll_gui_input(event):
	if event is InputEventMouseButton and not event.pressed:
		snap_scroll_delayed()
	if event is InputEventScreenTouch and not event.pressed:
		snap_scroll_delayed()

func snap_scroll_delayed():
	await get_tree().create_timer(0.3).timeout
	snap_scroll()

func snap_scroll():
	var target = round(float(tracker_scroll.scroll_horizontal) / TRACKER_SIZE) * TRACKER_SIZE
	scroll_to(target)

func scroll_to_current():
	var target = tracker_scroll.get_h_scroll_bar().max_value
	scroll_to(target)

func scroll_to(target):
	if snap_tween:
		snap_tween.kill()
	snap_tween = create_tween()
	snap_tween.tween_property(tracker_scroll, "scroll_horizontal", int(target), SNAP_ANIMATION_TIME)

func add_water(amount):
	get_today_tracker().add_water(amount)
	scroll_to_current()
	save_state()

func add_water_from_input():
	add_water(water_amount_input.value)

func set_goal():
	get_today_tracker().set_goal(water_goal_input.value)
	save_state()

func revert_action():
	get_today_tracker().revert_action()
	scroll_to_current()
	save_state()

func save_state():
	var data = {"first_entry_date": first_entry_date, "data": []}
	for day_tracker in get_tree().get_nodes_in_group("day_trackers"):
		data["data"].push_back(day_tracker.get_data())
	write_data_to_file(data)
	
func load_state():
	var data = read_data_from_file()
	first_entry_date = int(data["first_entry_date"])
	create_trackers_since(first_entry_date)
	for day_data in data["data"]:
		var day_tracker = get_day_tracker_by_unix(day_data["date"])
		day_tracker.load_data(day_data)

func create_save_file():
	print("Creating save file")
	first_entry_date = get_today_unix()
	var data = {"first_entry": first_entry_date, "data": []}
	var data_entry = {"water_amount": 0, "water_goal": 1, "date": first_entry_date}
	data["data"].push_back(data_entry)
	write_data_to_file(data)

func read_data_from_file():
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = save_file.get_line()
	print("Loading\n", json_string)
	var json = JSON.new()
	var _parse_result = json.parse(json_string)
	var data = json.data
	return data

func write_data_to_file(data):
	print("Saving\n", data)
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE_READ)
	var json_string = JSON.stringify(data)
	save_file.store_line(json_string)
	save_file.close()

func get_today_unix():
	var today = Time.get_date_dict_from_system()
	var midnight_dict = {
		"year": today.year,
		"month": today.month,
		"day": today.day,
		"hour": 0,
		"minute": 0,
		"second": 0
	}
	var midnight_unix = int(Time.get_unix_time_from_datetime_dict(midnight_dict))
	return midnight_unix

func get_next_day(day: int):
	return day+DAY_LENGTH

func create_trackers_since(date_to_add):
	while(date_to_add <= get_today_unix()):
		var day_tracker = create_day_tracker()
		day_tracker.load_data({"date": date_to_add, "water_amount": 0, "water_goal": 1})
		day_tracker.add_to_group("day_trackers")
		date_to_add = get_next_day(date_to_add)
	var placeholder_day_tracker = create_day_tracker() # add invisible placeholder for scrolling
	placeholder_day_tracker.modulate = Color(0, 0, 0, 0)

func create_day_tracker():
	var day_tracker = load("res://day.tscn").instantiate()
	tracker_container.add_child(day_tracker)
	return day_tracker

func get_day_tracker_by_unix(unix_time):
	var day_number = int((unix_time - first_entry_date)/DAY_LENGTH)
	return tracker_container.get_child(day_number)

func get_today_tracker():
	return get_day_tracker_by_unix(get_today_unix())
