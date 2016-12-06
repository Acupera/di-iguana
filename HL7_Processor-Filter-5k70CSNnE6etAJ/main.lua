local mapper = require "acupera.hl7Mapper"

function main(Data)
   local hl7Message, vmdConfigurationName = hl7.parse{vmd = 'example/demo.vmd', data = Data}
   
   if not mapper.isSupported(hl7Message) then
      local messageCode = hl7Message.MSH[9][1]:nodeValue()
      local messageEvent = hl7Message.MSH[9][2]:nodeValue()
      
      iguana.logInfo("" .. messageCode .. " " .. messageEvent .. " messages for .vmd configuration " .. vmdConfigurationName .. " are not supported by this channel.")
      
      return
   end
   
   queue.push{data = mapper.map(hl7Message)}
   
   return
end