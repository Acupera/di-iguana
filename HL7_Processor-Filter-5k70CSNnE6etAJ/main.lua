require 'log.annotate'
local mapper = require "acupera.hl7Mapper"

function main(Data)
   local hl7Message, vmdConfigurationName = hl7.parse{vmd = 'example/acupera.vmd', data = Data}
   
   if not mapper.isSupported(hl7Message) then
      iguana.logError(hl7Message.MSH[9][1]:nodeValue() .. " " .. hl7Message.MSH[9][2]:nodeValue() .. 
         " messages using the "..vmdConfigurationName.." .vmd configuration are not supported by this channel,"..
         " Sending Application: "..hl7Message.MSH[3][1]:nodeValue()..
         ", Sending Facility: "..hl7Message.MSH[4][1]:nodeValue()..".", iguana.messageId())
      
      return
   end
   
   queue.push{data = json.serialize{data=mapper.map(hl7Message)}}
   
   return
end