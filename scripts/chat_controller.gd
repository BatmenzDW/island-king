extends Control

class_name ChatController

@onready var chat: RichTextLabel = $MarginContainer/MarginContainer/ChatText
@onready var line_edit: LineEdit = $MarginContainer2/LineEdit
@onready var color: ColorRect = $MarginContainer/ColorRect

static var _inst : ChatController

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_inst = self

var editing : bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	if editing:
		return
	if Input.is_action_just_pressed("Open_Chat"):
		_set_visible(true)
	elif Input.is_action_just_pressed("Close_Chat"):
		_set_visible(false)

func _set_visible(_visible: bool) -> void:
	color.visible = _visible
	line_edit.visible = _visible

func _on_line_edit_editing_toggled(toggled_on: bool) -> void:
	editing = toggled_on

func _on_line_edit_text_submitted(new_text: String) -> void:
	var chat_text = "[%s] %s" % [GameState.player_name, new_text]
	_send_chat_to_server(chat_text)
	line_edit.text = ""

static func _send_chat_to_server(msg: String) -> void:
	_inst._rpc_send_chat_to_server.rpc_id(1, msg)

static func _send_chat_to_client(msg: String) -> void:
	_inst._rpc_send_chat_to_client.rpc(msg)

static func print_text_to_chat(msg: String, sender: String) -> void:
	_inst.chat.text += "[%s] %s\n" % [sender, msg]

@rpc("any_peer")
func _rpc_send_chat_to_server(msg: String) -> void:
	_send_chat_to_client(msg)

@rpc("authority")
func _rpc_send_chat_to_client(msg: String) -> void:
	chat.text += msg + "\n"


func _on_name_edit_editing_toggled(toggled_on: bool) -> void:
	editing = toggled_on
