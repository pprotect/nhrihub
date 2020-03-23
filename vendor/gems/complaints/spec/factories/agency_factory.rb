national_government_agencies = ["Civilian Secretariat for Police", "Department of Agriculture, Forestry and Fisheries", "Department of Arts and Culture ", "Department of Basic Education", "Department of Communications", "Department of Cooperative Governance and Traditional Affairs", "Department of Correctional Services", "Department of Defence", "Department of Economic Development", "Department of Energy ", "Department of Environmental Affairs ", "Department of Health", "Department of Higher Education and Training", "Department of Home Affairs", "Department of Human Settlements", "Department of International Relations and Cooperation", "Department of Justice and Constitutional Development", "Department of Labour", "Department of Military Veterans", "Department of Mineral Resources ", "Department of Performance Monitoring and Evaluation", "Department of Public Enterprises", "Department of Public Service and Administration", "Department of Public Works", "Department of Rural Development and Land Reform", "Department of Science and Technology", "Department of Social Development ", "Department of Sport and Recreation South Africa", "Department of Tourism ", "Department of Trade and Industry", "Department of Traditional Affairs", "Department of Transport", "Department of Water Affairs", "Department of Women, Children & People with Disabilities", "Independent Police Investigative Directorate", "National Treasury", "Public Administration Leadership and Management Academy", "Public Service Commission", "South African Police Service", "South African Revenue Service", "State Security Agency", "Statistics South Africa", "The Presidency"]
national_government_institutions = ["Independent Complaints Directorate", "National Intelligence Agency", "National Treasury", "Public Administration Leadership and Management Academy ", "Public Service Commission", "South African Police Service", "South African Revenue Service", "South African Secret Service", "Statistics South Africa"]
democracy_supporting_state_institutions = ["The Auditor-General", "The Commission for the Promotion and Protection of the Rights of Cultural, Religious and Linguistic Communities", "The Commission on Gender Equality", "The Human Rights Commission", "The Independent Electoral Commission", "The Public Protector"]
provincial_agencies = ["Agriculture", "Agriculture and Rural Development", "Agriculture, Land Reform and Rural Development", "Agriculture, Rural Development, Land and Environmental Affairs", "Arts and Culture", "Arts, Culture, Sports and Recreation", "Co-operative Governance and Traditional Affairs", "Co-operative Governance, Human Settlements and Traditional Affairs", "Community Safety", "Community Safety and Liaison", "Community Safety and Transport Management", "Community Safety, Security and Liaison", "Cooperative Governance and Traditional Affairs", "Cooperative Governance, Human Settlements and Traditional Affairs", "Cultural Affairs and Sport", "Culture, Sport and Recreation", "Economic Development", "Economic Development and Tourism", "Economic Development, Environment and Tourism", "Economic Development, Environment, Conservation and Tourism", "Economic Development, Environmental Affairs and Tourism", "Economic Development, Tourism and Environmental Affairs", "Economic, Small Business Development, Tourism and Environmental Affairs", "Education", "Environment and Nature Conservation", "Environmental Affairs and Development Planning", "Health", "Human Settlements", "Infrastructure Development", "Local Government", "Police, Roads and Transport", "Provincial Treasury", "Public Works", "Public Works and Infrastructure", "Public Works and Roads", "Public Works, Roads and Infrastructure", "Public Works, Roads and Transport", "Roads and Public Works", "Roads and Transport", "Rural Development and Agrarian Reform", "Safety and Liaison", "Social Development", "Sport and Recreation", "Sport, Arts and Culture", "Sport, Arts, Culture and Recreation", "Sport, Recreation, Arts and Culture", "Transport", "Transport and Community Safety", "Transport and Public Works", "Transport, Safety and Liaison", "Treasury", "e-Government"]
metro_municipalities = ["Buffalo City", "City of Cape Town", "City of Johannesburg", "City of Tshwane", "Ekurhuleni", "Mangaung", "Nelson Mandela Bay", "eThekwini"]
local_municipalities = ["!Kheis", "Abaqulusi", "Albert Luthuli", "Alfred Duma", "Amahlathi", "Ba-Phalaborwa", "Beaufort West", "Bela-Bela", "Bergrivier", "Big Five Hlabisa", "Bitou", "Blouberg", "Blue Crane Route", "Breede Valley", "Bushbuckridge", "Cape Agulhas", "Cederberg", "City of Matlosana", "Collins Chabane", "Dannhauser"]

FactoryBot.define do
  factory :agency do

    factory :national_government_agency do
      name { national_government_agencies.sample }
      type { 'NationalGovernmentAgency' }
    end

    factory :national_government_institution do
      name { national_government_institutions.sample }
      type { 'NationalGovernmentInstitution' }
    end

    factory :democracy_supporting_state_institution do
      name { democracy_supporting_state_institutions.sample }
      type { 'DemocracySupportingStateInstitution' }
    end

    factory :provincial_agency do
      name { provincial_agencies.sample }
      type { 'ProvincialAgency' }
    end

    factory :metropolitan_municipality do
      name { metropolitan_municipalities.sample }
      type { 'MetropolitanMunicipality' }
    end

    factory :local_municipality do
      name { local_municipalities.sample }
      type { 'LocalMunicipality' }
    end
  end
end
