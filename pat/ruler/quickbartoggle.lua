local msg = "pat_ruler_toggle"
if params and params[1] == "grid" then
	msg = "pat_tilegrid_toggle"
end

local enabled = world.sendEntityMessage(player.id(), msg):result()

if enabled then
	pane.playSound("/sfx/interface/nav_examine_on.ogg")
else
	pane.playSound("/sfx/interface/nav_examine_off.ogg")
end