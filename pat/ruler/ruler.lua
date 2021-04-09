require "/scripts/util.lua"
require "/scripts/vec2.lua"

local oldInit = init or function() end
local oldUpdate = update or function() end

local aimPosition = function()
	return world.sendEntityMessage(player.id(), "pat_ruler_aimPosition"):result()
end

function init()
	oldInit()
	
	player.setProperty("pat_ruler_paneOpen", false)
end

function update(dt)
	oldUpdate(dt)
	
	local techs = {
		head = player.equippedTech("head"),
		body = player.equippedTech("body"),
		legs = player.equippedTech("legs")
	}
	
	for _,tech in ipairs(player.availableTechs()) do
		for slot,ruler in pairs(techs) do
			if tech == "pat_ruler_"..slot and tech ~= ruler then
				player.makeTechUnavailable(tech)
			end
		end
	end
	
	--this sucks
	-- dont care
	local aim = aimPosition()
	if aim then
		aim = vec2.add(util.tileCenter(aim), {0, 2})
		local ePos = util.tileCenter(entity.position())
		local position = vec2.add(vec2.sub(ePos, entity.position()), {0, -2})
		
		local d = world.distance(aim, ePos)
		
		--what
		if d[1] == 0 and d[2] ~= 0 then
			if d[2] > 0 then
				position[2] = position[2] - 1
				d[2] = d[2] + 1
			else
				position[2] = position[2] + 1
				d[2] = d[2] - 1
			end
		end
		
		local xOffset = (d[1] < 0 and -0.5 or 0.5)
		local yOffset = (d[2] < 0 and -0.5 or 0.5)
		
		local display = {math.abs(d[1]), math.abs(d[2])}
		
		--generate poly
		local poly1 = {
			{xOffset, yOffset},
			{xOffset, -yOffset},
			{d[1] + xOffset, -yOffset},
			{d[1] + xOffset, yOffset}
		}
		local poly2 = {
			{d[1] + xOffset, yOffset},
			{d[1] + xOffset, d[2] + yOffset},
			{d[1] - xOffset, d[2] + yOffset},
			{d[1] - xOffset, yOffset}
		}
		
		if d[1] == 0 then
			poly1 = {}
			if d[2] == 0 then
				poly2 = {{xOffset, yOffset}, {xOffset, -yOffset}, {-xOffset, -yOffset}, {-xOffset, yOffset}}
				display[2] = 1
			end
			display[1] = 1
		else
			display[2] = display[2] + 1
		end
		
		--draw poly
		localAnimator.addDrawable({poly = poly1, color = "#00EEFF44", fullbright = true, position = position}, "Overlay+100")
		localAnimator.addDrawable({poly = poly2, color = "#00EEFF44", fullbright = true, position = position}, "Overlay+100")
		
		--draw lines
		local fullPoly = copy(poly1)
		for _,v in ipairs(poly2) do
			table.insert(fullPoly, copy(v))
		end
		
		for i = 1, #fullPoly do
			local line = {fullPoly[i], fullPoly[i+1] or fullPoly[1]}
			localAnimator.addDrawable({line = line, width = 1, color = "#00EEFF88", fullbright = true, position = position}, "Overlay+100")
		end
		
		--draw more lines
		local xMul = (d[1] < 0 and -1 or 1)
		for i = 1, math.abs(d[1]) - 1 do
			local x = i * xMul + xOffset
			local line = {{x, -0.5}, {x, 0.5}}
			localAnimator.addDrawable({line = line, width = 1, color = "#00EEFF88", fullbright = true, position = position}, "Overlay+100")
		end
		
		local yMul = (d[2] < 0 and -1 or 1)
		for i = 1, math.abs(d[2]) do
			local y = (i - 1) * yMul + yOffset
			local line = {{-0.5 + d[1], y}, {0.5 + d[1], y}}
			localAnimator.addDrawable({line = line, width = 1, color = "#00EEFF88", fullbright = true, position = position}, "Overlay+100")
		end
		
		--draw text
		local textPos = vec2.add(vec2.sub(aim, ePos), {1.25, -0.75})
		if d[2] < 0 then textPos[2] = textPos[2] - 2.5 end
		
		local str = string.format("%.0fx%.0f", display[1], display[2])
		for i = 1, #str do
			local h = str:sub(i, i)
			localAnimator.addDrawable({image = "/pat/ruler/numbers.png:"..h, fullbright = true, scale = 0.75, position = textPos}, "Overlay+100")
			
			textPos[1] = textPos[1] + (h == "1" and 0.75 or 1.25) * 0.75
		end
		
		world.debugText(vec2.print(display, 0), ePos, "red")
	end
end

-- h

-- local poly3 = {
	-- {xOffset, yOffset},
	-- {-xOffset, yOffset},
	-- {-xOffset, d[2] + yOffset},
	-- {xOffset, d[2] + yOffset}
-- }
-- local poly4 = {
	-- {xOffset, d[2] + yOffset},
	-- {d[1] + xOffset, d[2] + yOffset},
	-- {d[1] + xOffset, d[2] - yOffset},
	-- {xOffset, d[2] - yOffset}
-- }