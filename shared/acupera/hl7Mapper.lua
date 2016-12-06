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
   local address = combinedPatient.address()
   
   address.AddressLine1 = hl7Message.PID[11][1][1][1]:nodeValue()
   address.City = hl7Message.PID[11][1][3]:nodeValue()
   address.State = hl7Message.PID[11][1][4]:nodeValue()
   address.Postal = hl7Message.PID[11][1][5]:nodeValue()
   address.LastVerifiedDate = dateparse.parse(hl7Message.EVN[2][1]:nodeValue())
   
   if address.AddressLine1 ~= '' or address.City ~= '' or address.State ~= '' or address.Postal ~= '' then
      patient.Addresses[1] = address
   else
      patient.Addresses = nil
   end
   
   return
end

local function mapContacts(hl7Message, patient)
   local contact = combinedPatient.contact()
   
   -- ?? will this change per client ??
   contact.Value = hl7Message.PID[13][1][1]:nodeValue()
   --contact.ContactMethodType = 'Home' -- how to map this to our ListItem values?
   contact.LastVerifiedDate = dateparse.parse(hl7Message.EVN[2][1]:nodeValue())
   
   if contact.Value ~= '' then
      patient.Contacts[1] = contact
   else
      patient.Contacts = nil
   end
   
   return
end

local function mapLanguages(hl7Message, patient)
   local language = combinedPatient.language()
   
   language.Language = hl7Message.PID[15][1]:nodeValue()
   
   if language.Language ~= '' then
      patient.Languages[1] = language -- how to map this to our ListItem values?
   else
      patient.Languages = nil
   end
   
   return
end

local function mapPatientRecord(hl7Message, patient)
   patient.PatientRecord.FirstName = hl7Message.PID[5][1][2]:nodeValue()
   patient.PatientRecord.LastName = hl7Message.PID[5][1][1][1]:nodeValue()
   patient.PatientRecord.MiddleName = hl7Message.PID[5][1][3]:nodeValue()
   patient.PatientRecord.DateOfBirth = dateparse.parse(hl7Message.PID[7][1]:nodeValue())
   patient.PatientRecord.Gender = hl7Message.PID[8]:nodeValue() -- how to map this to our ListItem values?
   patient.PatientRecord.SSN = hl7Message.PID[19]:nodeValue()
   patient.PatientRecord.Race = hl7Message.PID[10][1][1]:nodeValue() -- how to map this to our lookups?
   patient.PatientRecord.Ethnicity = hl7Message.PID[22][1][1]:nodeValue() -- how to map this to our lookups?
   patient.PatientRecord.MaritalStatus = hl7Message.PID[16][1]:nodeValue() -- how to map this to our lookups?
   patient.PatientRecord.Facility = hl7Message.MSH[4][1]:nodeValue()
   
   if patient.PatientRecord.FirstName == '' and patient.PatientRecord.LastName == '' and patient.PatientRecord.MiddleName == ''
      or patient.PatientRecord.DateOfBirth == '' and patient.PatientRecord.Gender == '' and patient.PatientRecord.SSN == ''
      or patient.PatientRecord.Race == '' and patient.PatientRecord.Ethnicity == '' and patient.PatientRecord.MaritalStatus == '' then
      patient.PatientRecord = nil
   end
   
   return
end

local function mapPatientSearch(hl7Message, patient)
   local identifier = combinedPatient.identifier()
   
   identifier.AssigningAuthority = hl7Message.MSH[3][1]:nodeValue()
   identifier.IdentifierValue = hl7Message.PID[3][1][1]:nodeValue()
   patient.PatientSearch.PatientIdentifiers[1] = identifier
   patient.PatientSearch.FirstName = hl7Message.PID[5][1][2]:nodeValue()
   patient.PatientSearch.LastName = hl7Message.PID[5][1][1][1]:nodeValue()
   patient.PatientSearch.MiddleName = hl7Message.PID[5][1][3]:nodeValue()
   patient.PatientSearch.DateOfBirth = dateparse.parse(hl7Message.PID[7][1]:nodeValue())
   patient.PatientSearch.Gender = hl7Message.PID[8]:nodeValue()
   patient.PatientSearch.Client = hl7Message.INSURANCE[1].IN1[15]:nodeValue()
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
   mapLanguages(hl7Message, patient)
   
   return patient
end

function mappers.mapADTA31(hl7Message)
   return mapADTA28(hl7Message)
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