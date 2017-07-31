require "/scripts/util.lua"

function init()
  -- Bind Portrait Canvas
  portraitCanvas = widget.bindCanvas("portraitCanvas")
  
  -- Bind POV Canvas
  povCanvas = widget.bindCanvas("povCanvas")
  
  -- Command the player to lounge in the source entity
  player.lounge(pane.sourceEntity())
  
  -- Store "climax" progress widget
  self.progress = {}
  self.progress.climax = config.getParameter("progressClimax")
  
  -- Messenger storage
  self.messenger = {}

  self.timers = {}
  self.timers.pov = 0
  self.timers.dialog = 0
  self.timers.portrait = 0

  self.animation = {}
  
  self.animatePortrait = false
  
  self.previousDialog = ""
  
  -- Retrieve information about the portrait from the entity
  sendMessage("retrievePortrait", nil, true)
  
  -- Retrieve information about the animation from the entity
  sendMessage("retrieveAnimationData", nil, true)
  
  -- Retrieve information about the entity
  sendMessage("retrieveEntityData", nil, true)
  
  -- Retrieve information about the sextoys
  sendMessage("retrieveSextoys", nil, true)
end

function update(dt)
  updateMessage("isClimaxing", function(result)
    sendMessage("requestDialog", nil, true)
  end)

  updateMessage("prevSlot1Sextoy", function(result)
    self.sextoy = result
    
    updateSlot1Label()
  end)
  
  updateMessage("nextSlot1Sextoy", function(result)
    self.sextoy = result
    
    updateSlot1Label()
  end)

  -- Check for update on 'retrievePortrait'
  updateMessage("retrievePortrait", function(result)
    self.portrait = result
  end)

  -- Check for update on 'retrieveSextoys'
  updateMessage("retrieveSextoys", function(result)
    self.sextoy = result
    
    if (self.sextoy.slot1 ~= nil) then
      widget.setVisible("sextoySlot1", true)

      updateSlot1Label()
    end
  end)
  
  -- Send request to get next animation rate data
  sendMessage("retrieveEntityData", nil, true)
  
  updateMessage("retrieveAnimationData", function(result)
    self.animation.pov = result
    
    self.animation.pov.currentMinTempo = self.animation.pov.minTempo
    self.animation.pov.currentMaxTempo = self.animation.pov.maxTempo
    self.animation.pov.currentSustainedInterval = self.animation.pov.sustainedInterval
    self.animation.pov.currentAnimationRate = self.animation.pov.animationRate
  end)
  
  -- Check for update on 'retrieveEntityData'
  updateMessage("retrieveEntityData", function(result)
    self.entityData = result
  
    -- Retrieve information about the POV from the entity
    sendMessage("retrievePOV", nil, true)
    
    -- Update climax progress
    updateClimaxProgress()
  end)
  
  -- Check for update on 'retrievePOV'
  updateMessage("retrievePOV", function(result)
    self.pov = result
    
    local stateName = self.entityData.animatorState
    
    local state = {
      image  = "/interface/sexbound/pov/default.png",
      frames = 1,
      frameName = "default",
      cycle  = 1
    }
    
    if (result.states[stateName] ~= nil) then
      state = result.states[stateName]
    end
    
    self.pov = state
  end)
  
  -- Retrieve information about the dialog from the entity; if not busy
  sendMessage("requestDialog", nil, true)
  
  -- check for update on 'requestDialog'
  updateMessage("requestDialog", function(result)
    if (result) then
      if (result ~= self.previousDialog) then
        self.previousDialog = result
      
        self.animatePortrait = true
      
        widget.setText("sexDialog.text", result)
      end
    end
  end)
  
  -- Render all UI Canvases
  render(dt)
end

function render(dt)
  -- Clear Portrait Canvas
  portraitCanvas:clear()
  
  -- Clear POV Canvas
  povCanvas:clear()

  -- Render the portrait
  if (self.portrait ~= nil) then
    updatePortraitAnimation(dt)
  end
  
  -- Render the animated POV
  if (self.pov ~= nil and self.animation.pov ~= nil) then
    updatePOVAnimation(dt)
    
    povCanvas:drawImage("/interface/sexbound/recordfx.png", {0,0}, 1, "white", false)
  end
end

function sendMessage(message, args, wait)
  if (wait == nil) then wait = false end

  local owner = pane.sourceEntity()
  
  -- Prepare new message to store data
  if (self.messenger[message] == nil) then
    self.messenger[message] = {}
    self.messenger[message].promise = nil
    self.messenger[message].busy = false
  end
  
  -- Send out message and mark this messenger service as busy
  if not (self.messenger[message].busy) then
    if (args == nil) then
      self.messenger[message].promise = world.sendEntityMessage(owner, message)
    else
      self.messenger[message].promise = world.sendEntityMessage(owner, message, args)
    end
    
    if (wait) then
      self.messenger[message].busy = true
    end
  end
end

function updateClimaxProgress()
  local current    = self.entityData.climaxPoints.current
  local threshold  = self.entityData.climaxPoints.threshold
  local percentage = 0
  
  if (current) then
    percentage = (current / threshold) * 100
  end
  
  if (percentage < 33) then
    widget.setImage("progressClimax", "/interface/sexbound/sexuiprogress.png")
  end
  
  if (percentage >= 33 and percentage < 66) then
    widget.setImage("progressClimax", "/interface/sexbound/sexuiprogress1.png")
  end
  
  if (percentage >= 66 and percentage < 100) then
    widget.setImage("progressClimax", "/interface/sexbound/sexuiprogress2.png")
  end

  if (percentage >= 100) then
    widget.setImage("progressClimax", "/interface/sexbound/sexuiprogress3.png")
    
    -- hide climax progress
    widget.setVisible("progressClimax", false)
    
    -- show climax button
    widget.setVisible("btnCum", true)
  else
    -- show climax progress
    widget.setVisible("progressClimax", true)
    
    -- hide climax button
    widget.setVisible("btnCum", false)
  end
end

function updateMessage(message, callback)
  if (self.messenger[message] == nil) then return end

  local promise = self.messenger[message].promise

  if (promise and promise:finished()) then
    local result = promise:result()
    
    self.messenger[message].promise = nil
    self.messenger[message].busy = false
    
    callback(result)
  end
end

function updatePortraitAnimation(dt)
  local frame = 0

  if (self.animatePortrait) then
    self.timers.portrait = self.timers.portrait + dt
  
    local cycle = self.portrait.custom.cycle
    
    self.timers.dialog = math.min(cycle, self.timers.dialog + dt)
    frame = math.ceil(self.timers.dialog / cycle * self.portrait.custom.frames) - 1
    
    -- Reset Dialog Timer
    if (self.timers.dialog >= cycle) then
      self.timers.dialog = 0
    end
    
    -- Max timeout '3' seconds
    if (self.timers.portrait >= 3) then
      self.timers.portrait = 0
      self.animatePortrait = false
    end
  end
  
  portraitCanvas:drawImage(self.portrait.custom.image .. ":" .. frame, {0,0}, 1, "white", false)
end

function updatePOVAnimation(dt)
  local animationRate = 1
  local minTempo = 1
  local maxTempo = 2
  local sustainedInterval = 1
  local cycle = self.pov.cycle
  
  if (self.entityData.currentState == "sexState") then
    animationRate = self.animation.pov.currentAnimationRate
    minTempo = self.animation.pov.currentMinTempo
    maxTempo = self.animation.pov.currentMaxTempo
    sustainedInterval = self.animation.pov.currentSustainedInterval

    -- Set new animation rate
    self.animation.pov.currentAnimationRate = animationRate + (maxTempo / (sustainedInterval / dt))

    -- Throttle the animation rate
    if (animationRate > maxTempo) then
      self.animation.pov.currentAnimationRate = maxTempo
      animationRate = self.animation.pov.currentAnimationRate
    end
    
    -- Modify cycle with the animation rate
    cycle = self.pov.cycle / animationRate
  end
  -- Determine the next frame
  self.timers.pov = math.min(cycle, self.timers.pov + dt)
  local frame = math.ceil(self.timers.pov / cycle * self.pov.frames)
  
  -- Clamp the frame within the specified range
  if (self.pov.range ~= nil) then
    frame = util.clamp(frame, self.pov.range[1], self.pov.range[2])
  end
  
  -- Reset POV Timer
  if (self.timers.pov >= cycle) then
    self.timers.pov = 0
  end

  -- Reset animation rate
  if (animationRate >= maxTempo) then
    self.animation.pov.currentMinTempo          = self.animation.pov.nextMinTempo
    self.animation.pov.currentMaxTempo          = self.animation.pov.nextMaxTempo
    self.animation.pov.currentSustainedInterval = self.animation.pov.nextSustainedInterval
    
    -- Set animation rate to current min tempo
    self.animation.pov.currentAnimationRate = self.animation.pov.currentMinTempo 
    
    -- Send request to get next animation rate data
    sendMessage("retrieveAnimationData", nil, true)
  end
  
  local image = self.pov.image
  local frameName = self.pov.frameName
  local animationFrame = image .. ":" .. frameName .. "." .. frame
  
  -- Render the main image
  povCanvas:drawImage(animationFrame, {0,0}, 1, "white", false)

  -- Render slot1 sex toy over the main image
  if (self.sextoy.slot1 ~= nil) then
    if (self.sextoy.slot1.povImage ~= nil) then
      local slot1Image = self.sextoy.slot1.povImage
      local slot1AnimationFrame = slot1Image .. ":" .. frameName .. "." .. frame
    
      povCanvas:drawImage( slot1AnimationFrame, {0,0}, 1, "white", false)
    end
  end
end

function updateSlot1Label()
  local name = self.sextoy.slot1.name
  
  widget.setText("sextoySlot1.labelSlot1", name)
end

--- Callback functions

function doClimax()
  sendMessage("isClimaxing", nil, true)
end

function prevSlot1()
  sendMessage("prevSlot1Sextoy")
end

function nextSlot1()
  sendMessage("nextSlot1Sextoy")
end