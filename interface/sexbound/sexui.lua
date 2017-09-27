require "/scripts/sexbound/helper.lua"

-- Initializes the UI.
function init()
  self.entityType = world.entityType(pane.sourceEntity())

  --if (self.entityType == "object") then
  player.lounge(pane.sourceEntity()) -- Command the player to lounge in the source entity
  --end
  
  -- Storage (Canvas)
  self.canvas = {}
  self.canvas.userInput = widget.bindCanvas("inputCanvas")    -- Bind Input Canvas
  self.canvas.portrait  = widget.bindCanvas("portraitCanvas") -- Bind Portrait Canvas
  self.canvas.pov       = widget.bindCanvas("pov.canvas")     -- Bind POV Canvas
  
  -- Storage (Data)
  self.data = {}
  
  -- Storage (Portrait)
  self.portrait = {}
  
  -- Storage (POV)
  self.pov = {}
  
  -- Storage (Widget)
  self.widget = {}
  self.widget.climaxProgress = config.getParameter("climaxProgress")

  -- Initial animation rate
  self.animationRate = 1
  
  -- Set portrait to not animate - at first
  self.canAnimatePortrait = false

  -- Reset timers 
  resetTimers()
  
  local portraitData = world.entityPortrait( player.id(), "full" )
  
  local data = {}
  
  data.identity = helper.parsePortraitData(player.species(), player.gender(), portraitData)
  data.id       = player.id()
  data.gender   = player.gender()
  data.species  = player.species()
  data.type     = "player"
  data.uuid     = player.uniqueId()
  
  self.sourceEntity = pane.sourceEntity()
  
  -- Send initial message to store the player's data
  helper.sendMessage(self.sourceEntity, "setup-actor", data, false)
  
  if (self.entityType ~= "npc") then
    -- Send initial message to sync the ui with the source entity
    helper.sendMessage(self.sourceEntity, "sync-ui", nil, true)
    
    -- Send initial message to obtain the source entity's position data
    helper.sendMessage(self.sourceEntity, "sync-position", nil, true)
  end
end

function notifyFailedPlayerIdentity()
  player.radioMessage({
    messageId = "missingplayerid",
    unique    = false,
    text      = "^orange;Warning:^reset; Sexbound could not determine your player's identity! Run the ^green;BuildSexboundData^reset; executable file within your 'mods' folder to fix this!"
  })
end

function checkForPlayerIdentityFile()
  root.assetJson("/playeridentities.json")
end

-- Updates the UI.
function update(dt)
  if (self.entityType ~= "npc") then
    -- Update message (sync-ui)
    helper.updateMessage("sync-ui", function(result)
      -- Clear the sextoy data
      self.data.sextoy = {}
    
      if (result ~= nil) then
        self.data = helper.mergeTable(self.data, result)
      end
      
      if (self.previousDialog ~= self.data.sextalk.currentDialog) then
        self.previousDialog = self.data.sextalk.currentDialog
        
        self.canAnimatePortrait = true

        -- Set the dialog text to the new dialog
        widget.setText("sexDialog.text", self.data.sextalk.currentDialog)
      end
      
      -- Send another message to retrieve the data again
      helper.sendMessage(self.sourceEntity, "sync-ui", nil, true)
      
      startMusic()
    end)

    -- Update message (sync-position)
    helper.updateMessage("sync-position", function(result)
      -- Clear the position data
      self.data.position = {}
    
      self.data = helper.mergeTable(self.data, result)
      
      helper.sendMessage(self.sourceEntity, "sync-position", nil, true)
    end)
    
    -- Update functions
    updateClimaxProgress()
    
    updatePortrait(dt)
    
    updatePosition()
    
    updatePOV(dt)
    
    updateSextoy()
    
    -- Draw Phase
    render()
  end
end

-- Clears all canvases.
function clearAll()
  helper.each(self.canvas, function(k, v)
    self.canvas[k]:clear()
  end)
end

function dismissed()
  -- Reset the entity's position.
  helper.sendMessage(self.sourceEntity, "reset-position")
  
  -- Stop playing music
  stopMusic()
end

-- Renders the drawables for each canvas.
function render()
  clearAll()

  -- Portrait (Render)
  if (self.data.portrait ~= nil) then
    self.canvas.portrait:drawImage(self.data.portrait.custom.image .. ":" .. self.portrait.currentFrame, {0,0}, 1, "white", false)
  end
  
  -- POV (Render)
  if (self.data.pov ~= nil and self.data.pov.enabled) then
    local imageName = ""
  
    if (self.data.pov.matchPlayerGender) then 
      imageName = helper.replaceTag(self.pov.image, "gender", player.gender())
    else
      imageName = self.pov.image
    end
    
    -- Draw the current frame
    self.canvas.pov:drawImage(imageName .. ":" .. self.pov.frameName .. "." .. self.pov.currentFrame, {0,0}, 1, "white", false)

    -- Draw slot1 sex toy over the main image
    if (self.data.sextoy ~= nil and self.data.sextoy.slot1 ~= nil) then
      if (self.data.sextoy.slot1.povImage ~= nil) then
        self.canvas.pov:drawImage( self.data.sextoy.slot1.povImage .. ":" .. self.pov.frameName .. "." .. self.pov.currentFrame, {0,0}, 1, "white", false)
      end
    end
  
    -- Draw Cam Record Overlay
    self.canvas.pov:drawImage("/interface/sexbound/recordfx.png", {0,0}, 1, "white", false)
  end
end

-- Resets all timers used by the UI.
function resetTimers()
  -- Init timers
  self.timers = {}
  self.timers.pov      = 0
  self.timers.dialog   = 0
  self.timers.portrait = 0
end

function startMusic()
  if (self.data.music ~= nil and self.data.music.enabled) then
    world.sendEntityMessage(player.id(), "playAltMusic", self.data.music.tracks, self.data.music.fadeInTime)
  end
end

function stopMusic()
  if (self.data.music ~= nil and self.data.music.enabled) then
    world.sendEntityMessage(player.id(), "playAltMusic", jarray(), self.data.music.fadeOutTime)
  end
end

-- Updates the UI based upon the climax progress.
function updateClimaxProgress()
  if (self.data.climax == nil) then return end

  local percentage = (self.data.climax.points.current / self.data.climax.points.threshold) * 100

  if (percentage < 33) then
    widget.setImage("climaxProgress", "/interface/sexbound/sexuiprogress.png")
  end
  
  if (percentage >= 33 and percentage < 66) then
    widget.setImage("climaxProgress", "/interface/sexbound/sexuiprogress1.png")
  end
  
  if (percentage >= 66 and percentage < 100) then
    widget.setImage("climaxProgress", "/interface/sexbound/sexuiprogress2.png")
  end

  if (percentage >= 100) then
    widget.setImage("climaxProgress", "/interface/sexbound/sexuiprogress3.png")
    
    -- hide climax progress
    widget.setVisible("climaxProgress", false)
    
    -- show climax button
    widget.setVisible("btnCum", true)
  else
    -- show climax progress
    widget.setVisible("climaxProgress", true)
    
    -- hide climax button
    widget.setVisible("btnCum", false)
  end
end

-- Updates the UI based upon the portrait data.
function updatePortrait(dt)
  if (self.data.portrait ~= nil and self.canAnimatePortrait) then
    self.timers.portrait = self.timers.portrait + dt
  
    local cycle = self.data.portrait.custom.cycle
    
    self.timers.dialog = math.min(cycle, self.timers.dialog + dt)
    
    self.portrait.currentFrame = math.ceil(self.timers.dialog / cycle * self.data.portrait.custom.frames) - 1

    -- Reset Dialog Timer
    if (self.timers.dialog >= cycle) then
      self.timers.dialog = 0
    end
    
    -- Max timeout '3' seconds
    if (self.timers.portrait >= 3) then
      self.timers.portrait = 0
      self.canAnimatePortrait = false
      self.portrait.currentFrame = 0
    end
  end
end

function updatePosition()
  if (self.data.position == nil) then return end
  
  -- Show pov widget when pov module is enabled
  widget.setVisible("position", true)
  
  updatePositionLabel()
end

function updatePositionLabel()
  local name = self.data.position.name
  
  widget.setText("position.labelPosition", name)
end

-- Updates the POV based upon the POV data.
function updatePOV(dt)
  if (self.data.pov == nil) then return end

  -- Show pov widget when pov module is enabled
  widget.setVisible("pov", self.data.pov.enabled)

  -- Use the current animation state to determine which pov to store
  if (self.data.pov.states[self.data.animator.currentState] ~= nil) then
    self.pov = self.data.pov.states[self.data.animator.currentState]
  else
    self.pov = {
      cycle     = 1,
      frames    = 1,
      frameName = "default",
      image     = "/interface/sexbound/pov/default.png"
    }
  end

  -- Copy the value in the pov cycle
  local cycle = self.pov.cycle
  
  -- Default values
  local animationRate = 1
  local minTempo = 1
  local maxTempo = 1
  local sustainedInterval = 1
  
  -- If the current state machine state is sexState then try to adjust the animation rate
  if (self.data.sex.currentState == "sexState") then
    animationRate = self.data.animator.rate
    
    -- Set new values rate control variable values
    minTempo          = self.data.position.minTempo
    maxTempo          = self.data.position.maxTempo
    sustainedInterval = self.data.position.sustainedInterval
    
    -- Set new animation rate
    self.animationRate = animationRate + (maxTempo / (sustainedInterval / dt))

    -- Throttle the animation rate
    if (animationRate > maxTempo) then
      self.data.animator.currentAnimationRate = maxTempo
      animationRate = self.data.animator.currentAnimationRate
    end
    
    -- Modify cycle with the animation rate
    cycle = self.pov.cycle / animationRate
  end
  
  -- Determine the next frame
  self.timers.pov = math.min(cycle, self.timers.pov + dt)
  
  local frame = math.ceil(self.timers.pov / cycle * self.pov.frames)
  
  -- Clamp the frame within the specified range
  if (self.pov.range ~= nil) then
    frame = helper.clamp(frame, self.pov.range[1], self.pov.range[2])
  end
  
  -- Store the current frame for the renderer to reference
  self.pov.currentFrame = frame
  
  -- Reset POV Timer
  if (self.timers.pov >= cycle) then
    self.timers.pov = 0
  end

  -- Reset animation rate
  if (animationRate >= maxTempo) then
    self.data.animator.currentMinTempo          = self.data.animator.nextMinTempo
    self.data.animator.currentMaxTempo          = self.data.animator.nextMaxTempo
    self.data.animator.currentSustainedInterval = self.data.animator.nextSustainedInterval
    
    -- Set animation rate to current min tempo
    self.data.animator.currentAnimationRate = self.data.animator.currentMinTempo 
    
    -- Send request to get next animation rate data
    helper.sendMessage(self.sourceEntity, "sync-position", nil, true)
  end
end

-- Updates the POV based upon the POV data.
function updateSextoy()
  if (self.data.sextoy == nil) then return end

  if (self.data.sextoy.slot1 ~= nil) then
    widget.setVisible("sextoySlot1", true)

    updateSlot1Label()
  end
end

-- Updates the UI based upon the sex toy data.
function updateSlot1Label()
  local name = self.data.sextoy.slot1.name
  
  widget.setText("sextoySlot1.labelSlot1", name)
end

----------------------------------------------

-- Callback functions
function customClose()
  --pane.dismiss()
end

function doClimax()
  helper.sendMessage(self.sourceEntity, "isClimaxing")
end

function prevPosition()
  helper.sendMessage(self.sourceEntity, "changePosition", -1)
end

function nextPosition()
  helper.sendMessage(self.sourceEntity, "changePosition", 1)
end

function prevSlot1()
  helper.sendMessage(self.sourceEntity, "changeSlot1Sextoy", -1)
end

function nextSlot1()
  helper.sendMessage(self.sourceEntity, "changeSlot1Sextoy", 1)
end

function switchRole()
  helper.sendMessage(self.sourceEntity, "switch-role")
end