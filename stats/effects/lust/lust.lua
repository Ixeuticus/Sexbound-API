function init()
  status.setStatusProperty("lust", true)
end

function update(dt)
  if not status.statusProperty("lust") then
    effect.expire()
  end
end