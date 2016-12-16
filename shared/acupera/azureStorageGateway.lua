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
      combinedPatient = "dataintegration-combinedpatient"
   },
   queues = {
      combinedPatient = "dataintegration-combinedpatient"
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
      iguana.logWarning("Retrying for response code: "..response.code)
	   isSuccessful = false
   elseif not response.successCodes[response.code] then
      iguana.logError("Azure REST API respone code:"..response.code..", data: "..response.data..".")
   end
   
   return isSuccessful
end

local function blobPut(blobName, data)
   local restCall = function()
      local time = os.ts.gmdate(azureConstants.azureDateFormat)
      local message = data:gsub('\r', ''):compactWS()
      local result, httpStatus, headers = net.http.post{
         method="PUT",
         url=os.getenv("azureStorageAccount.blob.url")..blobName.."/"..iguana.messageId(),
         headers={
            Authorization = getAuthorizationHeader("PUT", time, message, blobName.."/"..iguana.messageId(), { "x-ms-blob-type:BlockBlob" }),
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

local function queuePut(queueName, data)
   if type(data) == table then data = json.parse{data=data} end
   
   local restCall = function()
      local time = os.ts.gmdate(azureConstants.azureDateFormat)
      local payload = '{ "body": "77u/'..filter.base64.enc('{ "blobName": "'..iguana.messageId()..'" }')..'" }'
      local message = '<QueueMessage><MessageText>'..filter.base64.enc(payload)..'</MessageText></QueueMessage>'
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
   
   blobPut(azureConstants.blobs.combinedPatient, data)
   
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