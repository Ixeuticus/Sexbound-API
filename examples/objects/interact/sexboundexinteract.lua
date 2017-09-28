require "/scripts/sexbound/sex.lua"

function init()
  -- Initialize the Sex API
  sex.init(function()
    object.setInteractive(true)
  end)
end

function update(dt)
  sex.loop(dt)
end

function onInteraction(args)
  local result = sex.handleInteract(args)
  
  if (result ~= nil) then return result end
end
