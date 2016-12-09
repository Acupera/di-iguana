local function send(combinedPatient)
   if type(combinedPatient) == table then combinedPatient = json.parse{data=combinedPatient} end
   -- TODO: save jsonMessage to Azure storage queue/service bus queue/topic
end

return {
   queue = {
      send = send
   }
}