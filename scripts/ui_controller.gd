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

@onready var heart_1: AnimatedSprite2D = $Control/Heart
@onready var heart_2: AnimatedSprite2D = $Control/Heart2
@onready var heart_3: AnimatedSprite2D = $Control/Heart3
@onready var heart_4: AnimatedSprite2D = $Control/Heart4
@onready var heart_5: AnimatedSprite2D = $Control/Heart5

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

const HEART_ANIMS : Array[String] = ["empty", "1fourth", "half", "3fourths"]
var current_health : int = 20:
	set(amount):
		current_health = amount
		
		var anim_selector = amount % 4
		
		if amount >= 4:
			heart_1.play("full")
		else:
			heart_1.play(HEART_ANIMS[anim_selector])
		
		if amount >= 8:
			heart_2.play("full")
		elif amount > 4:
			heart_2.play(HEART_ANIMS[anim_selector])
		else:
			heart_2.play("empty")
		
		if amount >= 12:
			heart_3.play("full")
		elif amount > 8:
			heart_3.play(HEART_ANIMS[anim_selector])
		else:
			heart_3.play("empty")
		
		if amount >= 16:
			heart_4.play("full")
		elif amount > 12:
			heart_4.play(HEART_ANIMS[anim_selector])
		else:
			heart_4.play("empty")
		
		if amount >= 20:
			heart_5.play("full")
		elif amount > 16:
			heart_5.play(HEART_ANIMS[anim_selector])
		else:
			heart_5.play("empty")

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
