require 'log.annotate'

local retry = require "retry"

local httpCallsAreLive = false
local azureConstants = {
   azureDateFormat = "%a, %d %b %Y %H:%M:%S GMT",
   azureAPIVersion = "2015-12-11",
   storageEmulatorAccountName = "devstoreaccount1",
   headers = {
      date = "x-ms-date",
      version = "x-ms-version",
      blobType = "x-ms-blob-type"
   },
   blobs = {
      combinedPatient = "dataintegration-combinedpatient",
      applicationInsights = "dataintegration-iguana-applicationinsights"
   },
   queues = {
      combinedPatient = "dataintegration-combinedpatient",
      applicationInsights = "dataintegration-iguana-applicationinsights"
   },
   retryDefaults = {
      times = 5,
      pause = 10
   }
}

local function getAuthorizationHeader(httpVerb, time, message, uriPath, headers)
   local key = filter.base64.dec(os.getenv("azureStorageAccount.primaryAccessKey"))
   local canonicalizedHeaders = function()
      local baseHeaders = {
         azureConstants.headers.date..":".. time,
         azureConstants.headers.version..":"..azureConstants.azureAPIVersion
      }
      
      if headers ~= nil then
         for i, header in pairs(headers) do
            table.insert(baseHeaders, header)
         end
      end
      
      table.sort(baseHeaders)
      
      return table.concat(baseHeaders, '\n').."\n"

   end
   local canonicalizedResource = function()
      local storageAccountName = os.getenv("azureStorageAccount.name")
      
      if storageAccountName == azureConstants.storageEmulatorAccountName then
         return "/"..storageAccountName.."/"..storageAccountName.."/"..uriPath
      else
         return "/"..storageAccountName.."/"..uriPath
      end
   end
   local signature = httpVerb .. "\n" ..
      "\n" ..  --Content-Encoding
      "\n" ..  --Content-Language
      string.len(message).."\n" ..  --Content-Length
      "\n" ..  --Content-MD5
      "application/x-www-form-urlencoded\n" ..  --Content-Type
      "\n" ..  --Date
      "\n" ..  --If-Modified-Since
      "\n" ..  --If-Match
      "\n" ..  --If-None-Match
      "\n" ..  --If-Unmodified-Since
      "\n" ..  --Range
      canonicalizedHeaders() ..
      canonicalizedResource()
   
   return "SharedKey "..os.getenv("azureStorageAccount.name")..":"..filter.base64.enc(crypto.hmac{data=signature, key=key, algorithm=crypto.algorithms()[11]})
end

local function retryRestErrorHandler(success, errMsgOrReturnCode, response)
   if not success then error(errMsgOrReturnCode) end
   
   local isSuccessful = true
   
   if response.code == 500 or response.code == 503 then
      iguana.logWarning("Retrying for response code: "..response.code, iguana.messageId())
	   isSuccessful = false
   elseif not response.successCodes[response.code] then
      iguana.logError("Azure REST API respone code:"..response.code..", data: "..response.data..".", iguana.messageId())
   end
   
   return isSuccessful
end

local function blobPut(blobContainer, data, messageSourceId)
   local restCall = function()
      local time = os.ts.gmdate(azureConstants.azureDateFormat)
      local message = json.serialize{data=data}:gsub('\r', ''):compactWS()
      local result, httpStatus, headers = net.http.post{
         method="PUT",
         url=os.getenv("azureStorageAccount.blob.url")..blobContainer.."/"..messageSourceId,
         headers={
            Authorization = getAuthorizationHeader("PUT", time, message, blobContainer.."/"..messageSourceId, { azureConstants.headers.blobType..":BlockBlob" }),
            [azureConstants.headers.date] = time,
            [azureConstants.headers.version] = azureConstants.azureAPIVersion,
            ["Content-Length"] = string.len(message),
            [azureConstants.headers.blobType] = "BlockBlob"
         },
         body=message
         ,debug=iguana.isTest()
         ,live=httpCallsAreLive
      }
      
      return true, { data = result, code = httpStatus, headers = headers, successCodes = { [201]=true } }
   end
   
   return retry.call{func=restCall, retry=azureConstants.retryDefaults.times, pause=azureConstants.retryDefaults.pause, errorfunc=retryRestErrorHandler}
end

local function queuePut(queueName, data, messageSourceId)
   local restCall = function()
      local time = os.ts.gmdate(azureConstants.azureDateFormat)
      local payloadBody = { blobName = messageSourceId }
      local payload = {
         Headers = {
            ["NServiceBus.MessageId"] = messageSourceId,
            ["NServiceBus.EnclosedMessageTypes"] = "DataIntegration.Messages.CombinedPatientCommand"
         },
         ReplyToAddress = iguana.id().."@test",
         Body = filter.base64.enc(json.serialize{data=payloadBody})
      }
      local message = '<QueueMessage><MessageText>'..filter.base64.enc(json.serialize{data=payload})..'</MessageText></QueueMessage>'
      local result, httpStatus, headers = net.http.post{
         method="POST",
         url=os.getenv("azureStorageAccount.queue.url")..queueName.."/messages",
         headers={
            Authorization = getAuthorizationHeader("POST", time, message, queueName.."/messages"),
            [azureConstants.headers.date] = time,
            [azureConstants.headers.version] = azureConstants.azureAPIVersion
         },
         body=message
         ,debug=iguana.isTest()
         ,live=httpCallsAreLive
      }
      
      return true, { data = result, code = httpStatus, headers = headers, successCodes = { [201]=true } }
   end
   
   blobPut(queueName, data, messageSourceId)
   
   return retry.call{func=restCall, retry=azureConstants.retryDefaults.times, pause=azureConstants.retryDefaults.pause, errorfunc=retryRestErrorHandler}
end

help.set{input_function = queuePut, help_data = {
      Title = "acupera.azureStorageGateway.queuePut",
      Usage = "azureStorageGateway.queue.put(queueName, data, messageSourceId)",
      Desc = "Pops a message to an Azure Storage Queue whose body contains a link to a Blob that stores the data.",
      Parameters = {
         { queueName = { Desc = "Name of the Azure Storage Queue." }},
         { data = { Desc = "Serialized json data." }},
         { messageSourceId = { Desc = "Unique identifier for the incoming message." }}
      },
      Returns = { { Desc = "bool" }},
      Examples = { 
         "azureStorageGateway.queue.put(azureStorageGateway.azureConstants.queues.combinedPatient, patient, patient.Metadata.SourceId)",
         "azureStorageGateway.azureConstants.queues.applicationInsights, exceptionTelemetry, exceptionTelemetry.context.properties['iguana.sourceId']" }
}}

return {
   azureConstants = azureConstants,
   blob = {
      put = blobPut
   },
   queue = {
      put = queuePut
   }
}