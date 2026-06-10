extends Node

@warning_ignore_start("unused_signal")
signal show_upgrade_text(upgrade: String, desc: String, cost: String)

signal hide_upgrade_text()

signal disable_wall(wall_name: String)

signal enable_door(door_name: String)

signal build_building(building: String)

signal reveal_upgrade(upgrade: String)

signal reset_run()

signal ap_reset()

signal upgrade_purchased(upgrade: String)

signal upgrade_unlocked(upgrade: String)

signal mult_processing_speed(speed: float)
