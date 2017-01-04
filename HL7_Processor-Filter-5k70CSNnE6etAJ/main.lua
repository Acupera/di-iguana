require 'log.annotate'
local translator = require "acupera.translator"
local mapper = require "acupera.hl7Mapper"

local function RunTranslator(hl7Message, vmdConfigurationName)
   if not mapper.isSupported(hl7Message) then
      iguana.logWarning(hl7Message.MSH[9][1]:nodeValue() .. " " .. hl7Message.MSH[9][2]:nodeValue() .. 
         " messages using the "..vmdConfigurationName.." .vmd configuration are not supported by this channel,"..
         " Sending Application: "..hl7Message.MSH[3][1]:nodeValue()..
         ", Sending Facility: "..hl7Message.MSH[4][1]:nodeValue()..".", iguana.messageId())
      
      return
   end
   
   queue.push{data = json.serialize{data=mapper.map(hl7Message)}}
   
   return
end

function main(Data)
   local hl7Message, vmdConfigurationName = hl7.parse{vmd = 'example/acupera.vmd', data = Data}
   
   translator.run(function() RunTranslator(hl7Message, vmdConfigurationName) end, hl7Message.MSH[10]:nodeValue())
end