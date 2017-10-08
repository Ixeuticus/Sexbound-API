--- Sex Module.
-- @module Sex
Sex = {}
Sex.__index = Sex

function Sex.new()
  local self = setmetatable({}, Sex)
  return self
end

require "/scripts/util.lua"
require "/scripts/sexbound/log.lua"

--- Initializes the Sex module.
function Sex:init()
  self.configuration = {file = "/scripts/sexbound/default.config", configObject = "sexboundConfig"}
  
  self.customization = {file = "sexboundCustom.config"}
  
  self.moduleName = "Sex"
  
  self:initLogging()
  
  self:loadConfiguration()
  
  self:checkCompatibility()
  
  if self:isCompatible() then
    self:loadCustomizations()
    
    self:initMessageHandlers()
  end
end

--- Check compatibility between this API and the mod.
function Sex:checkCompatibility()
  if self:getParameter("requiredVersion") then
    if self:matchRequiredVersion() then
      self.isCompatible = true
    else
      self.log:error("Sexbound API needs to updated to the latest version!")
      
      self.isCompatible = false
    end
  end
end

--- Returns whether or not this mod is compatible with the current API
function Sex:isCompatible()
  return self.isCompatible
end

--- Returns whether or not the current version of this API matches the mod's required version.
function Sex:matchRequiredVersion()
  local separator = "."
  local requiredVersion = util.split(self:getParameter("requiredVersion"), separator)
  local currentVersion  = util.split(self:getParameter("currentVersion"),  separator)

  -- Check major version matches
  if currentVersion[1] ~= requiredVersion[1] then return false end

  -- Check minor version is incompatible 
  if currentVersion[2] < requiredVersion[2] then return false end
  
  return true
end

--- Returns the base configuration.
function Sex:getConfiguration()
  return self.configuration.data
end

--- Returns the value of a specified parameter.
-- @param paramater string value with periods to separate parameters.
function Sex:getParameter(parameter)
  local parameters = util.split(parameter, ".")
  
  local config = self.configuration.data
  
  for _,p in ipairs(parameters) do
    if config[p] ~= nil then
      config = config[p]
    else return nil end
  end
  
  return config
end

--- Loads the base configuration and merges it with the mod's configuration.
function Sex:loadConfiguration()
  if not pcall(function()
    self.configuration.data = util.mergeTable(root.assetJson(self.configuration.file), config.getParameter(self.configuration.configObject))
  end) then
    self.log:warn("Failed to merge configuration! Falling back to default configuration file.")
    self.configuration.data = root.assetJson(self.configuration.file)
  end
end

--- Tries to load global customization settings.
function Sex:loadCustomizations()
  if not pcall(function()
    self.customization.data = root.assetJson(self.customization.file)
  end) then
    self.log:info("Unable to load customizations file.")
  end
end

--- Initializes logging.
function Sex:initLogging()
  self.log = Log.new({
    moduleName = self.moduleName
  })
end

--- Initializes message handlers.
function Sex:initMessageHandlers()
  self.log:info("Initializing message handlers.")
end