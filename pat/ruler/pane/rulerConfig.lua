function init()
	if player.getProperty("pat_ruler_paneOpen") == true then
		pane.dismiss()
	end
	
	local indexes = { head = -1, body = 0, legs = 1 }
	local slot = player.getProperty("pat_ruler_slot", "head")
	
	widget.setSelectedOption("changeSlot", indexes[slot] or -1)
	
	player.setProperty("pat_ruler_paneOpen", true)
end

function update(dt)
	if player.getProperty("pat_ruler_paneOpen") == false then
		pane.dismiss()
	end
end

function changeSlot(_, slot)
	local lastTech = player.getProperty("pat_ruler_lastTech")
	local oldSlot = player.getProperty("pat_ruler_slot", "head")
	local oldTech = player.equippedTech(oldSlot)
	
	player.makeTechUnavailable("pat_ruler_"..oldSlot)
	if lastTech then
		player.makeTechAvailable(lastTech)
		player.enableTech(lastTech)
		player.equipTech(lastTech)
	end
	
	local currentTech = player.equippedTech(slot)
	player.setProperty("pat_ruler_lastTech", currentTech)
	
	if oldTech == "pat_ruler_"..oldSlot then
		local tech = "pat_ruler_"..slot
		player.makeTechAvailable(tech)
		player.enableTech(tech)
		player.equipTech(tech)
	end
	
	player.setProperty("pat_ruler_slot", slot)
end

function dismissed()
	player.setProperty("pat_ruler_paneOpen", false)
end