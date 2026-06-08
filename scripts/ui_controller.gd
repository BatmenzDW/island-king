extends Control

@onready var crop_count_label: Label = $HBoxContainer/Crop/VBoxContainer/CropCount
@onready var sliced_count_label: Label = $HBoxContainer/SlicedCrop/VBoxContainer/SlicedCount
@onready var cooked_count_label: Label = $HBoxContainer/CookedCrop/VBoxContainer/CookedCount
@onready var gold_count_label: Label = $HBoxContainer/Gold/VBoxContainer/GoldCount
@onready var kingdom_money_label: Label = $Money/VBoxContainer/Label

@onready var upgrade_text: MarginContainer = $UpgradeText
@onready var upgrade_name: RichTextLabel = $UpgradeText/MarginContainer/VBoxContainer/UpgradeName
@onready var upgrade_desc: RichTextLabel = $UpgradeText/MarginContainer/VBoxContainer/UpgradeDesc
@onready var upgrade_cost: RichTextLabel = $UpgradeText/MarginContainer/VBoxContainer/UpgradeCost

var crop_count : int = 0:
	set(amount):
		crop_count = amount
		crop_count_label.text = str(amount)

var sliced_count : int = 0:
	set(amount):
		sliced_count = amount
		sliced_count_label.text = str(amount)

var cooked_count : int = 0:
	set(amount):
		cooked_count = amount
		cooked_count_label.text = str(amount)

var gold_count: int = 0:
	set(amount):
		gold_count = amount
		gold_count_label.text = str(amount)

var kingdom_money : float = 0:
	set(amount):
		kingdom_money = amount
		kingdom_money_label.text = str(amount)

func _ready() -> void:
	GameState.money_changed.connect(_on_money_changed)
	SignalBus.show_upgrade_text.connect(_on_show_upgrade_text)
	SignalBus.hide_upgrade_text.connect(_on_hide_upgrade_text)

func _on_money_changed(value: float) -> void:
	kingdom_money = value

func _on_show_upgrade_text(upgrade: String, desc: String, cost: String) -> void:
	upgrade_name.text = upgrade
	upgrade_desc.text = desc
	upgrade_cost.text = cost
	upgrade_text.show()

func _on_hide_upgrade_text() -> void:
	upgrade_text.hide()
