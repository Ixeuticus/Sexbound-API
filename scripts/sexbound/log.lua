--- Log Module.
-- @module Log
Log = {}
Log.__index = Log

--- Instantiates Log.
-- @param[opt] options
function Log.new(...)
  local self = setmetatable({}, Log)
  self:init(...)
  return self
end

--- Initializes Log.
-- @param[opt] options
function Log:init(options)
  self.options = options or {moduleName = "Unknown Module"}
end

--- Instructs util API to log error.
-- @param text string value
function Log:error(text)
  sb.logError(self:prepare(text))
end

--- Instructs util API to log info.
-- @param text string value
function Log:info(text)
  sb.logInfo(self:prepare(text))
end

--- Instructs util API to warn info.
-- @param text string value
function Log:warn(text)
  sb.logWarn(self:prepare(text))
end

--- Prepares text to be logged.
-- @param text string value
function Log:prepare(text)
  local pretext = "[ Sexbound API | " .. self.options.moduleName .. " ]"

  if text and type(text) == "table" then
    return pretext .. " : " .. sb.printJson( text )
  else return pretext .. " : " .. text end
  
  return pretext .. " : " .. "Null"
end