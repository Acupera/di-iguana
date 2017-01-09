local azureStorageGateway = require "acupera.azureStorageGateway"

local trackTypes = { }

local function getProjectCommitId()
   local channelConfig = xml.parse(iguana.channelConfig{guid=iguana.channelGuid()})
   local commitId = ''
   
   for i=1,channelConfig.channel:childCount() do
      if (channelConfig.channel[i]:nodeName() == "to_mapper"
            and channelConfig.channel.to_mapper.guid == iguana.project.guid()) then
         commitId = channelConfig.channel.to_mapper.commit_id
      elseif (channelConfig.channel[i]:nodeName() == "message_filter"
            and channelConfig.channel.message_filter.translator_guid == iguana.project.guid()) then
         commitId = channelConfig.channel.message_filter.translator_commit_id
      end
   end 
   
   return commitId
end

local function trackException(exceptionTelemetry)
   azureStorageGateway.queue.put(azureStorageGateway.azureConstants.queues.applicationInsights, exceptionTelemetry, exceptionTelemetry.context.properties["iguana.sourceId"])
end

function trackTypes.exceptionTelemetry(message, stackTrace)
   return {
      exception = {
         message = message,
         stackTrace = stackTrace
      },
      context = {
         properties = {
            ["iguana.channelGuid"] = iguana.channelGuid(),
            ["iguana.channelName"] = iguana.channelName(),
            ["iguana.projectCommitId"] = getProjectCommitId(),
            ["iguana.projectGuid"] = iguana.project.guid(),
            ["iguana.sourceId"] = '',
            ["iguana.messageId"] = iguana.messageId()
         }
      }
   }
end

help.set{input_function = trackTypes.exceptionTelemetry, help_data = {
      Title = "acupera.applicationInsights.trackTypes.exceptionTelemetry",
      Usage = "applicationInsights.trackTypes.exceptionTelemetry(message, stackTrace)",
      Desc = "Creates an ExceptionTelemetry object initialized with channel/project/message details for tracking.",
      Parameters = {
         { message = { Desc = "Error message." }},
         { stackTrace = { Desc = "Lua stack trace." }}
      },
      Returns = { { Desc = "ExceptionTelemetry table" }},
      Examples = { "applicationInsights.trackTypes.exceptionTelemetry(errorMessage, debug.traceback())" }
}}

help.set{input_function = trackException, help_data = {
      Title = "acupera.applicationInsights.trackException",
      Usage = "applicationInsights.trackException(exceptionTelemetry)",
      Desc = "Pushes an ExceptionTelemetry object to Azure Application Insights.",
      Parameters = { { exceptionTelemetry = { Desc = "ExceptionTelemetry object." }}},
      Returns = nil,
      Examples = { "applicationInsights.trackException(exceptionTelemetry)" }
}}

return {
   trackTypes = trackTypes,
	trackException = trackException
}