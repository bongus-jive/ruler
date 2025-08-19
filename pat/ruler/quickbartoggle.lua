local msg = params[1]
local id = player.id()
if msg and id ~= 0 and world.sendEntityMessage(id, msg):result() then
	pane.playSound("/sfx/interface/nav_examine_on.ogg")
else
	pane.playSound("/sfx/interface/nav_examine_off.ogg")
end
