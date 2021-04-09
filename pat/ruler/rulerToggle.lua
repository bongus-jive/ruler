local oldInit = init or function() end
local oldUpdate = update or function() end

function init()
	if pane then
		if not config.getParameter("pat_openOld") then
			toggleRuler()
			pane.dismiss()
		end
	end
	
	if activeItem then
		activeItem.setHoldingItem(false)
	end
	
	oldInit()
end

function toggleRuler()
	local slot = player.getProperty("pat_ruler_slot", "head")
	local tech = "pat_ruler_"..slot
	
	local current = player.equippedTech(slot)
	if current == tech then
		local old = player.getProperty("pat_ruler_lastTech")
		player.makeTechUnavailable(tech)
		if old then
			player.makeTechAvailable(old)
			player.enableTech(old)
			player.equipTech(old)
			player.setProperty("pat_ruler_lastTech", nil)
		end
		if pane then pane.playSound("/sfx/interface/nav_examine_off.ogg")
		else animator.playSound("rulerOff") end
	else
		player.setProperty("pat_ruler_lastTech", current)
		player.makeTechAvailable(tech)
		player.enableTech(tech)
		player.equipTech(tech)
		if pane then pane.playSound("/sfx/interface/nav_examine_on.ogg")
		else animator.playSound("rulerOn") end
	end
end

function activate(fireMode, shiftHeld)
	if shiftHeld and mcontroller.crouching() then
		player.interact("ScriptPane", "/pat/ruler/pane/rulerConfig.config")
	else
		toggleRuler()
	end
end

function update(dt, fireMode, shiftHeld, control)
	oldUpdate(dt)
	
	if activeItem then
		if shiftHeld and mcontroller.crouching() then
			activeItem.setInventoryIcon("/pat/ruler/rulerConfig.png")
		else
			activeItem.setInventoryIcon("/pat/ruler/ruler.png")
		end
	end
end

function uninit()
	if activeItem then
		activeItem.setInventoryIcon("/pat/ruler/ruler.png")
	end
end