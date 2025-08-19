require "/scripts/vec2.lua"

local Ruler = {}
pat_ruler = Ruler

function Ruler:init()
  if not storage.pat_ruler then storage.pat_ruler = {} end
  self.storage = setmetatable(storage.pat_ruler, nil)

  self.config = root.assetJson("/pat/ruler/ruler.config")
  
  self.characters = {}
  for _, char in pairs(self.config.charFrames) do
    local file = sb.replaceTags(self.config.charImage, {frame = char})
    local size = root.imageSize(file)
    self.characters[char] = { file = file, width = size[1] }
  end
  
  self.techSlot = root.techType(self.config.techName)
  self:restoreHeadTech()
  for _, tech in pairs(self.config.removedTechs) do
    player.makeTechUnavailable(tech)
  end

  self.lastPos = entity.position()
  self.fade = 1
  
  self.getAimPosition = player.aimPosition -- SE/OSB add this yayy :3
  if not self.getAimPosition then self:smuggleAimPosition() end
  
  self.checkBinds = input and input.bindDown ~= nil
  self.scaleText = camera and interface and camera.pixelRatio ~= nil and interface.scale ~= nil

  local function setHandler(n, f)
    message.setHandler(n, function(_, L, ...) if L then return f(self, ...) end end)
  end
  setHandler("pat_ruler_toggle", self.toggleRuler)
  setHandler("pat_tilegrid_toggle", self.toggleGrid)
end

function Ruler:equipTech(tech)
  if not tech then return end
  player.makeTechAvailable(tech)
  player.enableTech(tech)
  player.equipTech(tech)
end

function Ruler:restoreHeadTech()
  if player.equippedTech(self.techSlot) == self.config.techName then
    player.makeTechUnavailable(self.config.techName)
    self:equipTech(self.storage.lastTech)
    self.storage.lastTech = nil
  end
end

function Ruler:toggleRuler()
  self.storage.rulerEnabled = not self.storage.rulerEnabled
  return self.storage.rulerEnabled
end

function Ruler:toggleGrid()
  self.storage.gridEnabled = not self.storage.gridEnabled
  return self.storage.gridEnabled
end

function Ruler:smuggleAimPosition()
  self.storage.lastTech = player.equippedTech(self.techSlot)

  local mt = getmetatable''

  self.getAimPosition = mt.pat_ruler_aimPosition
  if self.getAimPosition then return end

  mt.pat_ruler_smuggleAimPosition = function(getAimPosition)
    mt.pat_ruler_smuggleAimPosition = nil
    mt.pat_ruler_aimPosition = getAimPosition
    self.getAimPosition = getAimPosition
    self:restoreHeadTech()
  end

  self:equipTech(self.config.techName)
end

function Ruler:update(dt)
  if not self.getAimPosition then return end
  
  if self.checkBinds then
    if input.bindDown("pat_ruler", "toggleRuler") then self:toggleRuler() end
    if input.bindDown("pat_ruler", "toggleGrid") then self:toggleGrid() end
  end

  if not self.storage.rulerEnabled and not self.storage.gridEnabled then return end

  self.dt = dt
  self.aimPos = self.getAimPosition()
  self.plrPos = entity.position()
  self.aimTile = { math.floor(self.aimPos[1]), math.floor(self.aimPos[2]) }
  self.plrTile = { math.floor(self.plrPos[1]), math.floor(self.plrPos[2]) }

  local moved = world.magnitude(self.plrPos, self.lastPos)
  if moved > self.config.fadeMovement then
    if self.fade > self.config.fadeMinimum then
      self.fade = math.max(self.config.fadeMinimum, self.fade - self.dt / self.config.fadeTime)
    end
  elseif self.fade < 1 then
    self.fade = math.min(1, self.fade + self.dt / self.config.fadeTime)
  end

  if self.storage.rulerEnabled then self:drawRuler() end
  if self.storage.gridEnabled then self:drawGrid() end

  self.lastPos = self.plrPos
end

function Ruler:drawRuler()
  local startTile = {self.plrTile[1], self.plrTile[2] - 2}
  local dist = world.distance(self.aimTile, startTile)
  local x, y = dist[1], dist[2]
  if x > 0 then startTile[1] = startTile[1] + 1 end
  if x == 0 then x = x + 1 end
  if y >= 0 then y = y + 1 end

  local xDir = x < 0 and -1 or 1
  local yDir = y < 0 and -1 or 1

  local layer = self.config.layer
  local drawable = {}
  drawable.fullbright = true
  drawable.color = self.config.color
  drawable.color[4] = self.config.polyAlpha * self.fade
  drawable.position = world.distance(startTile, self.plrPos)
  
  local poly = { {x, 1}, {x, 0}, {0, 0}, {0, 1} }
  drawable.poly = poly
  
  if y ~= 0 then
    if y <= 0 then
      poly[1], poly[2] = poly[2], poly[1]
      poly[3], poly[4] = poly[4], poly[3]
    end

    local x2 = x - xDir
    if math.abs(x) == 1 then
      poly[1], poly[4] = {x, y}, {x2, y}
    else
      local y2 = y > 0 and 1 or 0
      poly[5], poly[6], poly[7] = {x2, y2}, {x2, y}, {x, y}
    end
  end
  
  localAnimator.addDrawable(drawable, layer)
  
  drawable.poly = nil
  drawable.line = {}
  drawable.width = self.config.lineWidth
  drawable.color[4] = self.config.lineAlpha * self.fade
  
  poly[0] = poly[#poly]
  for i = 1, #poly do
    drawable.line[1] = poly[i - 1]
    drawable.line[2] = poly[i]
    localAnimator.addDrawable(drawable, layer)
  end

  for i = 1, math.abs(x) - 1 do
    local p = i * xDir
    drawable.line[1] = {p, 0}
    drawable.line[2] = {p, 1}
    localAnimator.addDrawable(drawable, layer)
  end

  for i = (y > 0 and 1 or 0), math.abs(y) - 1 do
    local p = i * yDir
    drawable.line[1] = {x, p}
    drawable.line[2] = {x - xDir, p}
    localAnimator.addDrawable(drawable, layer)
  end
  
  drawable.line, drawable.width = nil, nil
  drawable.centered = false
  drawable.color[4] = self.config.textAlpha * self.fade
  drawable.scale = self.config.textScale

  if self.scaleText then
    drawable.scale = drawable.scale / camera.pixelRatio() * (interface.scale() + 1)
  end
  
  local textPos = world.distance(self.aimPos, self.plrPos)
  textPos = vec2.add(textPos, self.config.textOffset)
  drawable.position = textPos
  layer = self.config.textLayer

  local str = string.format("%.0fx%.0f", math.abs(x), math.abs(dist[2]) + 1)
  for char in str:gmatch(".") do
    local cfg = self.characters[char]
    if cfg then
      drawable.image = cfg.file
      localAnimator.addDrawable(drawable, layer)
      textPos[1] = textPos[1] + (cfg.width * drawable.scale * 0.125)
    end
  end
end

function Ruler:drawGrid()
  local pos = world.distance(self.aimTile, self.plrPos)
  pos[1], pos[2] = pos[1] + 0.5, pos[2] + 0.5
  
  local drawable = self.config.gridDrawable
  drawable.position = pos
  drawable.color[4] = self.config.gridAlpha * self.fade
  
  localAnimator.addDrawable(drawable, self.config.layer)
end

local _init, _update = init, update
function init() _init() Ruler:init() end
function update(dt) _update(dt) Ruler:update(dt) end
