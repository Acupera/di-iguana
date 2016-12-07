local combinedPatient = require "acupera.combinedPatient"

local customMappings = {
   USMM = {
      keys = {
         {
            sendingApplication = "GPMS",
            sendingFacilities = { "All Saints Medical Center", "Allegiance Health", "Arlington Memorial", "Aventura Hospital", "Baptist Medical Center", "Baptist Medical Center - Nassau", "Baptist Medical Center Beaches", "Baptist Medical Center South", "Barbara A. Karmanos Cancer Institute", "Bay Area", "Baylor Medical Center at Uptown", "Baylor St Luke's Medical Center", "Beaumont Dearborn (Oakwood)", "Beaumont FH (Botsford)", "Beaumont Grosse Pointe", "Beaumont Royal Oak", "Beaumont Taylor (Heritage)", "Beaumont Trenton (South Shore)", "Beaumont Troy", "Beaumont Wayne (Annapolis)", "Boca Raton Regional Hospital", "Brandon Regional Hospital", "Bronson Hospital", "Bronson Lakeview", "Bronson Methodist", "Brooks Rehabilitation hospital", "Broward Healh Coral Springs (Coral Springs Medical Center)", "Broward Health Medical Center", "Carrolton", "Charlton Medical Center", "Cleveland Clinic- Stephanie Tubbs Jones Center", "Corpus Christi Medical Center:", "Covenant Health Care", "Crittenton", "Dallas Medical Center", "Dallas Regional Medical Center", "Detroit Receiving (DMC)", "Doctors Regional", "Flagler Hospital", "Florida Hospital Apopka ", "Florida Hospital Flagler", "Florida Hospital South (Orlando)", "Florida Hospital Tampa", "Florida Hospital Waterman", "Forida Hospital Altamonte", "Garden City Hospital", "Garland", "Genesys Regional Medical Center", "Grape Vine", "Greater Heights Hospital", "Hamilton Heart and Vascular", "Harper and Hutzel (DMC)", "Hays Hospital", "Health Central ", "Henry Ford Macomb", "Henry Ford Medical Center", "Henry Ford WB", "Henry Ford Wyandotte", "Holland Hospital", "Houston Methodist", "Hurley Medical Center", "Irving", "Jackson Memorial Hospital", "JPS (John Peter Smith)", "Katy Hospital", "Lake City Medical Center", "Lake Huron Medical Center (Mercy)", "Lakeland Community Hospital", "Lakeland Medical Center", "Lakeland Regional Medical Center", "Lakeside Hospital", "Mansfield Medical Center", "Mayo Clinic", "McKinney", "McLaren Bay Region", "McLaren Central Michigan", "McLaren Flint", "McLaren Greater Lansing and Ortho Hosp.", "McLaren Lapeer", "McLaren Macomb", "McLaren Oakland", "McLaren Port Huron", "Medical Center Arlington", "Medical City Hospital", "Memorial (Corpus Christi)", "Memorial City Hospital", "Memorial Hospital Jacksonville", "Memorial Hospital Tampa", "Mercy Health General Campus", "Mercy Health Hackley Hospital", "Mercy Health Lakeshore", "Mercy Health St Mary's", "Meridia Huron Hospital", "Methodist Azle", "Methodist Cleburne", "Methodist Fort Worth", "Methodist HEB", "Methodist SW Fort Worth", "Methodist West Hospital", "Metro Health Hospital", "MetroHealth Buckeye Health Center", "Mid-MI Medical Center Clare", "Mid-MI Medical Center Gladwin", "Mid-MI Medical Center Gratiot", "Mid-MI Medical Center Midland", "North Austin Medical Center", "North Florida Regional Medical Center", "North Shore Medical Center", "Northwest Hospital", "Northwest Regional", "Oak Hill Hospital", "Orange Park Medical Center", "Ortho and Spine", "Park Plaza Hospital", "Parkland Medical Center", "Pearland Hospital", "Plano", "Plantation General Hospital", "Plaza Medical Center", "Presbyterian Dallas", "Presbyterian Plano", "Regency North Central Ohio- Cleveland East", "Richardson Medical Center", "Saint Catherine Hospital", "Saint David's", "Saint John Hospital", "San Jacinto Hospital", "Seton Medical Center Austin", "Shoal Creek Hospital", "Shoreline", "Sinai-Grace (DMC)", "South Austin Medical Center", "South Haven Community Hospital", "South Seminole Hospital Orlando Health", "Southeast Hospital", "Southwest Hospital", "Southwest Hospital", "Sparrow Hospital", "Spectrum Health Big Rapids ", "Spectrum Health Pennock", "St Anthony's Hospital", "St David's Medical Center", "St David's Surgical Hospital", "St John Hospital and Medical Center", "St John Macomb", "St John Oakland", "St John Providence  ", "St John Providence Park", "St John River District", "St Joseph Mercy", "St Joseph Mercy Oakland", "St Joseph's Hospital", "St Joseph's Hospital- North", "St Luke's Hospital South", "St Mary Mercy", "St Mary's of MI", "St Mary's of MI Standish", "St Vincent's Medical Center", "St Vincent's Medical Center, Clay County", "St. Vincent Charity Medical Center", "Sugar Land Hospital", "Tampa General Hospital", "Texas Medical Center", "The Heart Hospital - Plano", "The Vintage Hospital", "The Woodlands Hospital", "U of M Medical Center", "U of M Mott Children's Hospital", "U of M Taubman Center", "Uinversity Hospitals Seidman Cancer Center", "University Hospital Cleveland Medical Center", "University Hospitals", "University Hospitals Foley ElderHealth Center", "University Hospitals MacDonald Woman's Hospital", "University Medical Center", "University Medical Center Brackenridge", "University of Chicago Medical Center", "University of FL Health", "University of FL Health Shands Hospital", "UT Southwestern Hospital", "Waxahachie", "Wekiva Springs Center (Mental Health)", "Westlake Medical Center", "White Rock", "Willowbrook Hospital"}
         }
      }
   }
}

function customMappings.USMM.mapADTA28(hl7Message, patient)
	local tag = combinedPatient.tag()
   
   tag.Name = "Patient.CustomTags.ETOC"
   tag.Value = "TRUE"
   tag.Type = "Bool"
   table.insert(patient.Tags, tag)
   
   return
end

local function getCustomMapper(hl7Message)
   local messageCode = hl7Message.MSH[9][1]:nodeValue()
   local messageEvent = hl7Message.MSH[9][2]:nodeValue()
   
   for clientName, clientMapping in pairs(customMappings) do
      for i, keyMapping in pairs(clientMapping.keys) do
         for j, facility in pairs(keyMapping.sendingFacilities) do
            customMapper = customMappings[clientName]["map"..messageCode..messageEvent]
            
            if customMapper ~= nil then return customMapper end
         end
      end
   end
   
   return nil
end

local function map(hl7Message, patient)
   local customMapper = getCustomMapper(hl7Message)
   
   if customMapper ~= nil then customMapper(hl7Message, patient) end
end

return {
   map = map
}