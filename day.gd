extends TextureProgressBar

var actions = []
var water_amount = 0
var water_goal = 1
var date: int

func _process(_delta: float) -> void:
	update_displays()

func get_data():
	return {
			"date": date,
			"water_amount": water_amount,
			"water_goal": water_goal
		}

func load_data(data):
	water_amount = data["water_amount"]
	water_goal = data["water_goal"]
	date = data["date"]

func revert_action():
	if actions.size() > 0:
		water_amount = max(0, water_amount-actions.back())
		actions.pop_back()

func add_water(amount):
	actions.append(amount)
	water_amount += float(amount)

func set_goal(amount):
	water_goal = amount

func update_displays():
	self.value = water_amount
	self.max_value = water_goal
	var date_dictionary = Time.get_datetime_dict_from_unix_time(date)
	$Label.text = str(date_dictionary["day"])+"."+str(date_dictionary["month"])
