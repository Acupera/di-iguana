local applicationInsights = require "acupera.applicationInsights"

local function errorHandler(errorMessage)
   return applicationInsights.trackTypes.exceptionTelemetry(errorMessage, debug.traceback())
end

local function run(main, messageSourceId)
   local statusCode, exceptionTelemetry = xpcall(main, errorHandler)
	
   if not statusCode then
      iguana.logError("This message failed and will not be processed.\nError Message: "..exceptionTelemetry.exception.message.."\nStrack Track: "..exceptionTelemetry.exception.stackTrace, iguana.messageId())
      exceptionTelemetry.context.properties["iguana.sourceId"] = messageSourceId
      applicationInsights.trackException(exceptionTelemetry)
   end
end

help.set{input_function = run, help_data = {
      Title = "acupera.translator.run",
      Usage = "translator.run(function() mainFunction() end, messageSourceId)",
      Desc = "This is the core wrapper for any acupera Translator component allowing all code to be managed in a standard fashion, including global error handling.",
      Parameters = {
         { main = { Desc = "Translator's main function to be run." }},
         { messageSourceId = { Desc = "The message's unique identifier to trace through the DI process end-to-end." }}
      },
      Returns = nil,
      Examples = { "translator.run(function() RunTranslator(hl7Message, vmdConfigurationName) end, hl7Message.MSH[10]:nodeValue())" }
}}

return {
   run = run
}