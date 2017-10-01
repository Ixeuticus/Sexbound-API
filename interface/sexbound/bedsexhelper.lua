require "/scripts/sexbound/helper.lua"

init = function()
  self.sourceEntity = pane.sourceEntity()

  helper.sendMessage(self.sourceEntity, "retrieve-sexnode-id", nil, true) -- Get the bed sex node id from source
end

update = function()
  helper.updateMessage("retrieve-sexnode-id", function(result)
    local sexNodeId = result
  
    player.lounge(sexNodeId, 1)
    
    local sexuiConfig = root.assetJson("/interface/sexbound/sexui.config")
    
    player.interact("ScriptPane", sexuiConfig, sexNodeId)
    
    pane.dismiss()
  end)
end