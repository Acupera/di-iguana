local dateparse = require "date.parse"
local combinedPatient = require "acupera.combinedPatient"
local customMapper = require "acupera.hl7MapperCustom"

local mappers = {}

local function getMapperName(hl7Message)
   local messageCode = hl7Message.MSH[9][1]:nodeValue()
   local messageEvent = hl7Message.MSH[9][2]:nodeValue()
   
   return "map"..messageCode..messageEvent
end

local function isSupported(hl7Message)
   return mappers[getMapperName(hl7Message)] ~= nil
end

local function mapAddresses(hl7Message, patient)
   for i = 1, #hl7Message.PID[11] do
      local address = combinedPatient.address()
   
      address.AddressLine1 = hl7Message.PID[11][i][1][1]:nodeValue()
      address.AddressLine2 = hl7Message.PID[11][i][2]:nodeValue()
      address.City = hl7Message.PID[11][i][3]:nodeValue()
      address.State = hl7Message.PID[11][i][4]:nodeValue()
      address.Postal = hl7Message.PID[11][i][5]:nodeValue()
      address.LastVerifiedDate = dateparse.parse(hl7Message.EVN[2][1]:nodeValue())

      if address.AddressLine1 ~= '' or address.City ~= '' or address.State ~= '' or address.Postal ~= '' then
         table.insert(patient.Addresses, address)
      end
   end
   
   return
end

local function mapContacts(hl7Message, patient)
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

local function mapCoverages(hl7Message, patient)
   for i = 1, #hl7Message.INSURANCE do
      local coverage = combinedPatient.coverage()
   
      coverage.StartDate = dateparse.parse(hl7Message.INSURANCE[i].IN1[12]:nodeValue())
      coverage.EndDate = dateparse.parse(hl7Message.INSURANCE[i].IN1[13]:nodeValue())
      coverage.LastCoverageValidationDateTime = dateparse.parse(hl7Message.EVN[2][1]:nodeValue())
      coverage.IsPrimary = hl7Message.INSURANCE[i].IN1[22]:nodeValue() -- is this correct for base functionality or should it just be a custom thing?
      coverage.RelationshipToSubscriber = hl7Message.INSURANCE[i].IN1[17][1]:nodeValue() -- is this correct for base functionality or should it just be a custom thing?

      if coverage.StartDate ~= '' and coverage.RelationshipToSubscriber ~= '' then
         table.insert(patient.Coverages, coverage)
      end
   end
   
   return
end

local function mapIdentifiers(hl7Message, patient)
   for i = 1, #hl7Message.PID[3] do
      local identifier = combinedPatient.identifier()
      
      identifier.IdentifierValue = hl7Message.PID[3][i][1]:nodeValue()
      identifier.StartDate = dateparse.parse(hl7Message.EVN[2][1]:nodeValue())
      table.insert(patient.Identifiers, identifier)
   end
   
   return
end

local function mapLanguages(hl7Message, patient)
   local language = combinedPatient.language()
   
   language.Language = hl7Message.PID[15][2]:nodeValue()
   
   if language.Language ~= '' then
      table.insert(patient.Languages, language)
   end
   
   return
end

local function mapPatientRecord(hl7Message, patient)
   patient.PatientRecord.FirstName = hl7Message.PID[5][1][2]:nodeValue()
   patient.PatientRecord.LastName = hl7Message.PID[5][1][1][1]:nodeValue()
   patient.PatientRecord.MiddleName = hl7Message.PID[5][1][3]:nodeValue()
   patient.PatientRecord.DateOfBirth = dateparse.parse(hl7Message.PID[7][1]:nodeValue())
   patient.PatientRecord.DateOfDeath = dateparse.parse(hl7Message.PID[29][1]:nodeValue())
   patient.PatientRecord.Gender = hl7Message.PID[8]:nodeValue()
   patient.PatientRecord.SSN = hl7Message.PID[19]:nodeValue()
   patient.PatientRecord.Race = hl7Message.PID[10][1][2]:nodeValue()
   patient.PatientRecord.Ethnicity = hl7Message.PID[22][1][2]:nodeValue()
   patient.PatientRecord.MaritalStatus = hl7Message.PID[16][1]:nodeValue()
   patient.PatientRecord.Facility = hl7Message.MSH[4][1]:nodeValue()
   
   return
end

local function mapPatientSearch(hl7Message, patient)
   for i = 1, #hl7Message.PID[3] do
      local identifier = combinedPatient.identifierInfo()
      
      identifier.IdentifierValue = hl7Message.PID[3][i][1]:nodeValue()
      table.insert(patient.PatientSearch.PatientIdentifiers, identifier)
   end
   
   for i = 1, #hl7Message.INSURANCE do
      local coverageSearchInfo = combinedPatient.coverageSearchInfo()
      
      coverageSearchInfo.HealthPlan = hl7Message.INSURANCE[i].IN1[4][1][1]:nodeValue()
      table.insert(patient.PatientSearch.PatientCoverages, coverageSearchInfo)
   end
   
   patient.PatientSearch.FirstName = hl7Message.PID[5][1][2]:nodeValue()
   patient.PatientSearch.LastName = hl7Message.PID[5][1][1][1]:nodeValue()
   patient.PatientSearch.MiddleName = hl7Message.PID[5][1][3]:nodeValue()
   patient.PatientSearch.DateOfBirth = dateparse.parse(hl7Message.PID[7][1]:nodeValue())
   patient.PatientSearch.Gender = hl7Message.PID[8]:nodeValue()
   patient.PatientSearch.HealthPlan = hl7Message.INSURANCE[1].IN1[4][1][1]:nodeValue()
   patient.PatientSearch.SubscriberId = hl7Message.INSURANCE[1].IN1[36]:nodeValue()
   patient.PatientSearch.SocialSecurityNumber = hl7Message.PID[19]:nodeValue()
   
   return
end

function mappers.mapADTA28(hl7Message)
   local patient = combinedPatient.patient()
   
   mapPatientSearch(hl7Message, patient)
   mapPatientRecord(hl7Message, patient)
   mapAddresses(hl7Message, patient)
   mapContacts(hl7Message, patient)
   mapCoverages(hl7Message, patient)
   mapIdentifiers(hl7Message, patient)
   mapLanguages(hl7Message, patient)
   
   return patient
end

function mappers.mapADTA31(hl7Message)
   return mappers.mapADTA28(hl7Message)
end

local function map(hl7Message)
   if not isSupported(hl7Message) then return nil end
   
   local patient = mappers[getMapperName(hl7Message)](hl7Message)
   
   customMapper.map(hl7Message, patient)
   
   return patient
end

return {
   isSupported = isSupported,
   map = map
}