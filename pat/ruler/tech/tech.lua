function init()
  local mt = getmetatable''
  if mt then pcall(mt.pat_ruler_smuggleAimPosition, tech.aimPosition) end
end
