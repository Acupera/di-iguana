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

return {
   run = run
}