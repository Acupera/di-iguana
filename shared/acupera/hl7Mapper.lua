local dateparse = require "date.parse"
local combinedPatient = require "acupera.combinedPatient"
local customMapper = require "acupera.hl7MapperCustom"

local entityMappers = {}
local messageMappers = {}

function entityMappers.mapAddresses(hl7Message, patient)
   for i = 1, #hl7Message.PID[11] do
      local address = combinedPatient.address()
   
      address.Address1 = hl7Message.PID[11][i][1][1]:nodeValue()
      address.Address2 = hl7Message.PID[11][i][2]:nodeValue()
      address.City = hl7Message.PID[11][i][3]:nodeValue()
      address.State = hl7Message.PID[11][i][4]:nodeValue()
      address.Postal = hl7Message.PID[11][i][5]:nodeValue()
      address.LastVerifiedDate = dateparse.parse(hl7Message.EVN[2][1]:nodeValue())
      address.IsPreferred = false

      if address.AddressLine1 ~= '' or address.City ~= '' or address.State ~= '' or address.Postal ~= '' then
         table.insert(patient.Addresses, address)
      end
   end
   
   return
end

function entityMappers.mapContacts(hl7Message, patient)
   for i = 1, #hl7Message.PID[13] do
      local contact = combinedPatient.contact()
      
      if hl7Message.PID[13][i][1]:nodeValue() ~= '' then
         contact.ContactMethodType = "HOME"
         contact.Value = hl7Message.PID[13][i][1]:nodeValue()
         contact.LastVerifiedDate = dateparse.parse(hl7Message.EVN[2][1]:nodeValue())
         table.insert(patient.Contacts, contact)
      end
      
      if hl7Message.PID[13][i][4]:nodeValue() ~= '' then
         contact.ContactMethodType = "EMAIL"
         contact.Value = hl7Message.PID[13][i][4]:nodeValue()
         contact.LastVerifiedDate = dateparse.parse(hl7Message.EVN[2][1]:nodeValue())
         table.insert(patient.Contacts, contact)
      end
   end
   
   return
end

function entityMappers.mapCoverages(hl7Message, patient)
   for i = 1, #hl7Message.INSURANCE do
      local coverage = combinedPatient.coverage()
   
      coverage.StartDate = dateparse.parse(hl7Message.INSURANCE[i].IN1[12]:nodeValue())
      coverage.EndDate = dateparse.parse(hl7Message.INSURANCE[i].IN1[13]:nodeValue())
      coverage.LastCoverageValidationDateTime = dateparse.parse(hl7Message.EVN[2][1]:nodeValue())
      
      if coverage.StartDate ~= '' then
         table.insert(patient.Coverages, coverage)
      end
   end
   
   return
end

function entityMappers.mapIdentifiers(hl7Message, patient)
   for i = 1, #hl7Message.PID[3] do
      local identifier = combinedPatient.identifier()
      
      identifier.IdentifierValue = hl7Message.PID[3][i][1]:nodeValue()
      identifier.StartDate = dateparse.parse(hl7Message.EVN[2][1]:nodeValue())
      table.insert(patient.Identifiers, identifier)
   end
   
   return
end

function entityMappers.mapLanguages(hl7Message, patient)
   local language = combinedPatient.language()
   
   language.Language = hl7Message.PID[15][2]:nodeValue()
   
   if language.Language ~= '' then
      table.insert(patient.Languages, language)
   end
   
   return
end

function entityMappers.mapPatientRecord(hl7Message, patient)
   patient.PatientRecord.FirstName = hl7Message.PID[5][1][2]:nodeValue()
   patient.PatientRecord.LastName = hl7Message.PID[5][1][1][1]:nodeValue()
   patient.PatientRecord.MiddleName = hl7Message.PID[5][1][3]:nodeValue()
   patient.PatientRecord.DateOfBirth = dateparse.parse(hl7Message.PID[7][1]:nodeValue())
   patient.PatientRecord.DateOfDeath = dateparse.parse(hl7Message.PID[29][1]:nodeValue())
   patient.PatientRecord.GenderString = hl7Message.PID[8]:nodeValue()
   patient.PatientRecord.SSN = hl7Message.PID[19]:nodeValue()
   patient.PatientRecord.Facility = hl7Message.MSH[4][1]:nodeValue()
   
   return
end

function entityMappers.mapPatientSearch(hl7Message, patient)
   for i = 1, #hl7Message.PID[3] do
      local identifier = combinedPatient.identifierInfo()
      
      identifier.IdentifierValue = hl7Message.PID[3][i][1]:nodeValue()
      table.insert(patient.PatientSearch.PatientIdentifiers, identifier)
   end
   
   for i = 1, #hl7Message.INSURANCE do
      local coverageSearchInfo = combinedPatient.coverageSearchInfo()
      
      coverageSearchInfo.HealthPlan = hl7Message.INSURANCE[i].IN1[4][1][1]:nodeValue()
      coverageSearchInfo.SubscriberId = hl7Message.INSURANCE[i].IN1[36]:nodeValue()
      table.insert(patient.PatientSearch.PatientCoverages, coverageSearchInfo)
   end
   
   patient.PatientSearch.FirstName = hl7Message.PID[5][1][2]:nodeValue()
   patient.PatientSearch.LastName = hl7Message.PID[5][1][1][1]:nodeValue()
   patient.PatientSearch.MiddleName = hl7Message.PID[5][1][3]:nodeValue()
   patient.PatientSearch.DateOfBirth = dateparse.parse(hl7Message.PID[7][1]:nodeValue())
   patient.PatientSearch.GenderString = hl7Message.PID[8]:nodeValue()
   patient.PatientSearch.SocialSecurityNumber = hl7Message.PID[19]:nodeValue()
   
   return
end

function messageMappers.mapADTA28(hl7Message)
   local patient = combinedPatient.patient()
   
   patient.Metadata.SourceId = hl7Message.MSH[10]
   entityMappers.mapPatientSearch(hl7Message, patient)
   entityMappers.mapPatientRecord(hl7Message, patient)
   entityMappers.mapAddresses(hl7Message, patient)
   entityMappers.mapContacts(hl7Message, patient)
   entityMappers.mapCoverages(hl7Message, patient)
   entityMappers.mapIdentifiers(hl7Message, patient)
   entityMappers.mapLanguages(hl7Message, patient)
   
   return patient
end

function messageMappers.mapADTA31(hl7Message)
   return messageMappers.mapADTA28(hl7Message)
end

local function getMapperName(hl7Message)
   local messageCode = hl7Message.MSH[9][1]:nodeValue()
   local messageEvent = hl7Message.MSH[9][2]:nodeValue()
   
   return "map"..messageCode..messageEvent
end

local function isSupported(hl7Message)
   return messageMappers[getMapperName(hl7Message)] ~= nil and customMapper.isSupported(hl7Message)
end

local function map(hl7Message)
   if not isSupported(hl7Message) then return nil end
   
   local patient = messageMappers[getMapperName(hl7Message)](hl7Message)
   
   customMapper.map(hl7Message, patient)
   
   return patient
end

return {
   isSupported = isSupported,
   map = map
}