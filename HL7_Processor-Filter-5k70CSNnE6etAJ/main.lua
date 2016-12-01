local mapper = require "mapper"
local queue = require "queue"

function main(Data)
   local hl7Message, Name = hl7.parse{vmd = 'example/demo.vmd', data = Data}
   
   if Name == "ADT" then
      local patient = mapper.Map(hl7Message, hl7Message.MSH[9][2]:nodeValue())
      
      if patient ~= nil then
         queue.send(patient)
      else
         iguana.logInfo("This " .. Name .. " " .. messageType .. " message was filtered.")
      end
   else
      iguana.logInfo("This " .. Name .. " message was filtered.")
   end
   
   return
end