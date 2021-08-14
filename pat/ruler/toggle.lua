local enabled = world.sendEntityMessage(player.id(), "pat_ruler_toggle"):result()

if enabled then
	pane.playSound("/sfx/interface/nav_examine_on.ogg")
else
	pane.playSound("/sfx/interface/nav_examine_off.ogg")
end