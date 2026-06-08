extends Node

@warning_ignore_start("unused_signal")
signal show_upgrade_text(upgrade: String, desc: String, cost: String)

signal hide_upgrade_text()

signal disable_wall(wall_name: String)

signal reset_run()
