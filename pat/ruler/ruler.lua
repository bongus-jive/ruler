require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/messageutil.lua"

local oldInit = init or function() end
local oldUpdate = update or function() end

local drawRuler, rulerEnabled, gridEnabled, aimPosition

local function equipTech(t)
	if not t then return end
  player.makeTechAvailable(t)
  player.enableTech(t)
  player.equipTech(t)
end

local function toggleRuler()
  rulerEnabled = not rulerEnabled
  player.setProperty("pat_ruler_enabled", rulerEnabled)
  return rulerEnabled
end

local function toggleGrid()
  gridEnabled = not gridEnabled
  player.setProperty("pat_tilegrid_enabled", gridEnabled)
  return gridEnabled
end


function init()
	oldInit()
	
	rulerEnabled = player.getProperty("pat_ruler_enabled", false)
	gridEnabled = player.getProperty("pat_tilegrid_enabled", false)
	
  --the toggler handling
	message.setHandler("pat_ruler_toggle", localHandler(toggleRuler))
	message.setHandler("pat_tilegrid_toggle", localHandler(toggleGrid))
  
  --get aimposition
	if starExtensions then
    aimPosition = player.aimPosition
  else
    local m = getmetatable''
    m.pat_ruler = {}
    m.pat_ruler.done = function()
      aimPosition = m.pat_ruler.aimPosition
      equipTech(player.getProperty("pat_rulerLastTech"))
      player.makeTechUnavailable("pat_ruler_head")
      m.pat_ruler = nil
    end
    
    local head = player.equippedTech("head")
    if head ~= "pat_ruler_head" then
      player.setProperty("pat_rulerLastTech", head)
    end
    equipTech("pat_ruler_head")
  end
	
	--remove very old techs
	for _,t in ipairs(player.availableTechs()) do
		if t == "pat_ruler_body" or t == "pat_ruler_legs" then
			player.makeTechUnavailable(t)
		end
	end
end


function update(dt)
	oldUpdate(dt)
  
  if not aimPosition then return end
	
  --starextensions binds
  if starExtensions then
    if input.bindDown("pat_ruler", "toggleRuler") then toggleRuler() end
    if input.bindDown("pat_ruler", "toggleGrid") then toggleGrid() end
  end
  
  if not rulerEnabled and not gridEnabled then return end
  
  local epos = entity.position()
  local eposCenter = util.tileCenter(epos)
  local eDist = world.distance(eposCenter, epos)
  local aim = util.tileCenter(aimPosition())
  local d = world.distance(aim, eposCenter)
  
  if gridEnabled then
    local pos = vec2.add(d, eDist)
    localAnimator.addDrawable({image = "/pat/ruler/grid.png", fullbright = true, scale = 0.5, position = pos}, "Overlay+101")
  end
  
  if rulerEnabled then
    drawRuler(eposCenter, eDist, aim, d)
  end
end

-- the fuck
drawRuler = function(eposCenter, eDist, aim, d)
  local position = vec2.add(eDist, {0, -2})
  aim[2] = aim[2] + 2
  d[2] = d[2] + 2
  
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
  local textPos = vec2.add(world.distance(aim, eposCenter), {1.25, -0.75})
  if d[2] < 0 then textPos[2] = textPos[2] - 2.5 end
  
  local str = string.format("%.0fx%.0f", display[1], display[2])
  for i = 1, #str do
    local h = str:sub(i, i)
    localAnimator.addDrawable({image = "/pat/ruler/numbers.png:"..h, fullbright = true, scale = 0.75, position = textPos}, "Overlay+100")
    
    textPos[1] = textPos[1] + (h == "1" and 0.75 or 1.25) * 0.75
	end
end