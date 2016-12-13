require 'log.annotate'

local azureConstants = {
   azureDateFormat = "%a, %d %b %Y %H:%M:%S GMT",
   azureAPIVersion = "2015-12-11",
   headers = {
      date = "x-ms-date",
      version = "x-ms-version"
   },
   queues = {
      combinedPatient = "dataintegration-combinedpatient"
   }
}

local function getSignature(httpVerb, time, message)
   local key = filter.base64.dec(os.getenv("azureStorageAccount.primaryAccessKey"))
   local canonicalizedHeaders = azureConstants.headers.date..":".. time ..
      "\n"..azureConstants.headers.version..":"..azureConstants.azureAPIVersion.."\n"
   local canonicalizedResource = "/"..os.getenv("azureStorageAccount.name").."/"..azureConstants.queues.combinedPatient.."/messages"
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
      canonicalizedHeaders ..   
      canonicalizedResource
   
   return filter.base64.enc(crypto.hmac{data=signature, key=key, algorithm=crypto.algorithms()[11]})
end

local function put(combinedPatient)
   if type(combinedPatient) == table then combinedPatient = json.parse{data=combinedPatient} end
   
   local time = os.ts.gmdate(azureConstants.azureDateFormat)
   local contents = combinedPatient:gsub('\r', ''):compactWS()
   local message = '<QueueMessage><MessageText>'..filter.base64.enc(contents)..'</MessageText></QueueMessage>'
   local result = net.http.post{
      method="POST",
      url="https://"..os.getenv("azureStorageAccount.name")..".queue.core.windows.net/"..azureConstants.queues.combinedPatient.."/messages",
      headers={
         Authorization = "SharedKey "..os.getenv("azureStorageAccount.name")..":".. getSignature("POST", time, message),
         [azureConstants.headers.date] = time,
         [azureConstants.headers.version] = azureConstants.azureAPIVersion
      },
      body=message
      --,debug=true
      --,live=true
   }
end

return {
   queue = {
      put = put
   }
}