require "/scripts/util.lua"

sextalk = {}

function sextalk.init()
  -- Handle request for current dialog
  message.setHandler("requestDialog", function()
    return sextalk.currentDialog()
  end)
  
  local sexTalkConfig = config.getParameter("sexboundConfig").sextalk
  
  util.each(sexTalkConfig, function(k,v)
    self.sexboundConfig.sextalk[k] = v
  end)
  
  -- Load the dialog config file
  self.dialog = root.assetJson(self.sexboundConfig.sextalk.dialog)

  self.currentDialog = "*Silent*"
  
  -- Select initial dialog
  sextalk.selectAuto("idleState")
end

function sextalk.currentDialog()
  return self.currentDialog
end

function sextalk.hasDialog()
  --
end

sextalk.isEnabled = function()
  return self.sexboundConfig.sextalk.enabled
end

function sextalk.selectAuto(state)
  if not sextalk.isEnabled() then return nil end

  if (mode == "random") then
    return sextalk.selectRandom(state)
  end

  return nil
end

function sextalk.method()
  return self.sexboundConfig.sextalk.method
end

function sextalk.selectRandom(state)
  if not sextalk.isEnabled() then return nil end

  local choices = self.dialog[state].default.default
  
  if not isEmpty(choices) then
    -- Try not to repeat the last dialog
    for i=1,5 do
      self.currentDialog = util.randomChoice(choices)
      
      if (self.currentDialog ~= self.previousDialog) then
        break
      end
    end
  else
    self.currentDialog = "*Speechless*"
  end
  
  if (sextalk.method() == "chatbubblePortrait") then
    object.sayPortrait(sextalk.currentDialog(), portrait.getCurrentPortrait())
  end
  
  if (sextalk.method() == "chatbubble") then
    object.say(sextalk.currentDialog())
  end 
  
  self.previousDialog = self.currentDialog
  
  return self.currentDialog
end