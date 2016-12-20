local function patient()
   local patient = {
      Metadata = {
         SourceId = ''
      },
      PatientSearch = {
         PatientIdentifiers = {},
         PatientCoverages = {},
         FirstName = '',
         LastName = '',
         MiddleName = '',
         DateOfBirth = '',
         GenderString = '',
         Client = '',
         HealthPlan = '',
         SubscriberId = '',
         SocialSecurityNumber = '',
      },
	   PatientRecord = {
         FirstName = '',
         LastName = '',
         MiddleName = '',
         DateOfBirth = '',
         DateOfDeath = '',
         GenderString = '',
         SSN = '',
         Race = '',
         Ethnicity = '',
         MaritalStatus = '',
         Facility = '',
         TimeZone = ''
      },
      Addresses = {},
      Coverages = {},
      Contacts = {},
      Identifiers = {},
      Languages = {},
      Tags = {}
   }
   
   return patient
end

local function address()
   return {
      AddressType = '',
      AddressLine1 = '',
      Address2 = '',
      City = '',
      State = '',
      Postal = '',
      LastVerifiedDate = '',
      IsPreferred = '',
      TimeZone = ''
   }
end

local function contact()
	return {
      Value = '',
      ContactMethodType = '',
      LastVerifiedDate = '',
      TimeZone = ''
   }
end

local function coverage()
   return {
      StartDate = '',
      EndDate = '',
      LastCoverageValidationDateTime = '',
      IsPrimary = '',
      RelationshipToSubscriber = '',
      TimeZone = ''
   }
end

local function coverageSearchInfo()
   return {
      Client = '',
      HealthPlan = '',
      LineOfBusiness = ''
   }
end

local function identifier()
   return {
      AssigningAuthority = '',
      IdentifierValue = '',
      IdentifierType = '',
      IdentifierName = '',
      StartDate = '',
      TimeZone = ''
   }
end

local function identifierInfo()
   return {
      AssigningAuthority = '',
      IdentifierValue = '',
      IdentifierType = '',
      IdentifierName = ''
   }
end

local function language()
   return {
      Language = ''
   }
end

local function tag()
   return {
      Name = '',
      Value = '',
      Type = '',
      TimeZone = ''
   }
end

return {
   address = address,
   patient = patient,
   contact = contact,
   coverage = coverage,
   coverageSearchInfo = coverageSearchInfo,
   identifier = identifier,
   identifierInfo = identifierInfo,
   language = language,
   tag = tag
}