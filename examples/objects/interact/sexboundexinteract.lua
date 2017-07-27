require "/scripts/sexbound/sex.lua"

function init()
  -- Initialize the Sex API
  sex.init()
end

function update(dt)
  sex.loop(dt)
end

function onInteraction(args)
  local result = sex.handleInteract()
  
  if (result ~= nil) then return result end
end
