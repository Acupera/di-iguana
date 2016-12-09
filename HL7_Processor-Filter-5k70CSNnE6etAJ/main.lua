require 'log.annotate'
local mapper = require "acupera.hl7Mapper"

function main(Data)
   local hl7Message, vmdConfigurationName = hl7.parse{vmd = 'example/acupera.vmd', data = Data}
   local patient = mapper.map(hl7Message)
   
   if patient == nil then
      iguana.logError(hl7Message.MSH[9][1]:nodeValue() .. " " .. hl7Message.MSH[9][2]:nodeValue() .. " messages for .vmd configuration " .. vmdConfigurationName .. " are not supported by this channel.")
      
      return
   end
   
   queue.push{data = json.serialize{data=patient, alphasort=true}}
   
   return
end