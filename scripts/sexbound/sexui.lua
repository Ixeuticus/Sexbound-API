require "/scripts/util.lua"

sexui = {}

sexui.init = function()
  local sexUIConfig = config.getParameter("sexboundConfig").sexui
  
  if (sexUIConfig ~= nil) then
    util.each(sexUIConfig, function(k,v)
      self.sexboundConfig.sexui[k] = v
    end)
  end
end

sexui.isEnabled = function()
  if self.sexboundConfig.sexui ~= nil and not isEmpty(self.sexboundConfig.sexui) then
    if (self.sexboundConfig.sexui.enabled ~= nil) then
      return self.sexboundConfig.sexui.enabled
    else
      -- Assumed to be enabled
      return true
    end
  end
  
  -- Assumed to be disabled
  return false
end