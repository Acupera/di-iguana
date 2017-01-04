require 'log.annotate'

local retry = require "retry"

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
            Authorization = getAuthorizationHeader("PUT", time, message, blobContainer.."/"..messageSourceId, { "x-ms-blob-type:BlockBlob" }),
            [azureConstants.headers.date] = time,
            [azureConstants.headers.version] = azureConstants.azureAPIVersion,
            ["Content-Length"] = string.len(message),
            [azureConstants.headers.blobType] = "BlockBlob"
         },
         body=message
         ,debug=iguana.isTest()
         ,live=true
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
            ["NServiceBus.MessageId"] = util.guid(128),
            ["NServiceBus.CorrelationId"] = "38fc10c3-aa7b-4737-9702-a6de00904155",
            ["NServiceBus.MessageIntent"] = "Send",
            ["NServiceBus.Version"] = "5.2.14",
            ["NServiceBus.ContentType"] = "application/json",
            ["NServiceBus.EnclosedMessageTypes"] = "DataIntegration.Messages.CombinedPatientCommand, DataIntegration.Messages, Version=1.0.0.0, "..
               "Culture=neutral, PublicKeyToken=null;DataIntegration.Messages.IDataIntegrationCommand, DataIntegration.Messages, Version=1.0.0.0, "..
               "Culture=neutral, PublicKeyToken=null;DataIntegration.Messages.IDataIntegrationRunCommand, DataIntegration.Messages, Version=1.0.0.0, "..
               "Culture=neutral, PublicKeyToken=null;DataIntegration.Messages.DataIntegrationCommand, DataIntegration.Messages, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null",
            ["NServiceBus.ConversationId"] = "264804b5-60e6-4957-84e7-a6de00904178",
            ["WinIdName"] = iguana.id(),
            ["NServiceBus.OriginatingMachine"] = "KASTURI-LAPTOP",
            ["NServiceBus.OriginatingEndpoint"] = "DataIntegrationConsole",
            ["$.diagnostics.originating.hostid"] = "cc27376f935b88a46e56a6ae9e905324"
         },
         ReplyToAddress = iguana.id().."@test",
         Body = "77u/"..filter.base64.enc(json.serialize{data=payloadBody})
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
         ,live=true
      }
      
      return true, { data = result, code = httpStatus, headers = headers, successCodes = { [201]=true } }
   end
   
   blobPut(queueName, data, messageSourceId)
   
   return retry.call{func=restCall, retry=azureConstants.retryDefaults.times, pause=azureConstants.retryDefaults.pause, errorfunc=retryRestErrorHandler}
end

return {
   azureConstants = azureConstants,
   blob = {
      put = blobPut
   },
   queue = {
      put = queuePut
   }
}