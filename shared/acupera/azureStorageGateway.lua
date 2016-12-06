local function send(combinedPatient)
   local jsonMessage = json.serialize{data=combinedPatient,alphasort=true}
   -- TODO: save jsonMessage to Azure storage queue/service bus queue/topic
end

return {
   queue = {
      send = send
   }
}