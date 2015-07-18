module CodeLists

  @@location_type = {
    "ADM1"  => "first-order administrative division",
    "ADM2"  => "second-order administrative division",
    "CNS"   => "concession area",
    "FRM"   => "farm",
    "PCL"   => "political entity (i.e. a country)",
    "PPL"   => "populated place",
    "PPLA"  => "seat of a first-order administrative division",
    "PPLA2" => "seat of a second-order administrative division",
    "PPLC"  => "capital of a political entity",
    "RES"   => "reserve"
  }

  @@geographical_precision = {
    1 => "Exact location",
    2 => "Near exact location",
    3 => "Second order administrative division",
    4 => "First order administrative division",
    5 => "Estimated coordinates",
    6 => "Independent political entity",
    7 => "Unclear - capital",
    8 => "Local or national capital",
    9 => "Unclear - country"
  }

  @@global_recipients = {
    "NS" => "Non Specific Country",
    "ZZ" => "Multilateral Organisation",
    "AC" => "Administrative/Capital"
  }

  @@transaction_types = {
    "C"  => "Commitment",            
    "D"  => "Disbursement",          
    "E"  => "Expenditure",         
    "IF" => "Incoming Funds",      
    "IR" => "Interest Repayment",  
    "LR" => "Loan Repayment",      
    "R " => "Reimbursement",         
    "QP" => "Purchase of Equity",  
    "QS" => "Sale of Equity",      
    "CG" => "Credit Guarantee"  
  }

  @@mime_types = {
    "application/msword" => "Word Document",
    "application/vnd.ms-excel" => "Excel Spreadsheet",
    "application/octet-stream" => "Binary file",
    "application/pdf" => "PDF Document",
    "text/html" => "Web Page"

  }

  @@transaction_titles = {
    "C"  => "Commitment (obligation to provide funding)",            
    "D"  => "Disbursement (fund transfer to implementing agency)",          
    "E"  => "Expenditure (project spend)",
    "IF" => "First installment from DFID"
  }

  @@activity_statuses = {
    1 => "Pipeline/identification",
    2 => "Implementation",
    3 => "Completion",
    4 => "Post-completion",
    5 => "Cancelled"
  }

  @@sectors = {
    11110 => 'Education policy and administrative management',
    11120 => 'Education facilities and training',
    11130 => 'Teacher training',
    11182 => 'Educational research',
    11220 => 'Primary education',
    11230 => 'Basic life skills for youth and adults',
    11240 => 'Early childhood education',
    11320 => 'Secondary education',
    11330 => 'Vocational training',
    11420 => 'Higher education',
    11430 => 'Advanced technical and managerial training',
    12110 => 'Health policy and administrative management',
    12181 => 'Medical education/training',
    12182 => 'Medical research',
    12191 => 'Medical services',
    12220 => 'Basic health care',
    12230 => 'Basic health infrastructure',
    12240 => 'Basic nutrition',
    12250 => 'Infectious disease control',
    12261 => 'Health education',
    12262 => 'Malaria control',
    12263 => 'Tuberculosis control',
    12281 => 'Health personnel development',
    13010 => 'Population policy and administrative management',
    13020 => 'Reproductive health care',
    13030 => 'Family planning',
    13040 => 'STD control including HIV/AIDS',
    13081 => 'Personnel development for population and reproductive health',
    14010 => 'Water resources policy and administrative management',
    14015 => 'Water resources protection',
    14020 => 'Water supply and sanitation - large systems',
    14030 => 'Basic drinking water supply and basic sanitation',
    14040 => 'River development',
    14050 => 'Waste management/disposal',
    14081 => 'Education and training in water supply and sanitation',
    15110 => 'Economic and development policy/planning',
    15120 => 'Public sector financial management',
    15130 => 'Legal and judicial development',
    15140 => 'Government administration',
    15150 => 'Strengthening civil society',
    15161 => 'Elections',
    15162 => 'Human rights',
    15163 => 'Free flow of information',
    15164 => "Women's equality organisations and institutions",
    15210 => 'Security system management and reform',
    15220 => 'Civilian peace-building, conflict prevention and resolution',
    15230 => 'Post-conflict peace-building (UN)',
    15240 => 'Reintegration and SALW control',
    15250 => 'Land mine clearance',
    15261 => 'Child soldiers (Prevention and demobilisation)',
    16010 => 'Social/ welfare services',
    16020 => 'Employment policy and administrative management',
    16030 => 'Housing policy and administrative management',
    16040 => 'Low-cost housing',
    16050 => 'Multisector aid for basic social services',
    16061 => 'Culture and recreation',
    16062 => 'Statistical capacity building',
    16063 => 'Narcotics control',
    16064 => 'Social mitigation of HIV/AIDS',
    21010 => 'Transport policy and administrative management',
    21020 => 'Road transport',
    21030 => 'Rail transport',
    21040 => 'Water transport',
    21050 => 'Air transport',
    21061 => 'Storage',
    21081 => 'Education and training in transport and storage',
    22010 => 'Communications policy and administrative management',
    22020 => 'Telecommunications',
    22030 => 'Radio/television/print media',
    22040 => 'Information and communication technology (ICT)',
    23010 => 'Energy policy and administrative management',
    23020 => 'Power generation/non-renewable sources',
    23030 => 'Power generation/renewable sources',
    23040 => 'Electrical transmission/ distribution',
    23050 => 'Gas distribution',
    23061 => 'Oil-fired power plants',
    23062 => 'Gas-fired power plants',
    23063 => 'Coal-fired power plants',
    23064 => 'Nuclear power plants',
    23065 => 'Hydro-electric power plants',
    23066 => 'Geothermal energy',
    23067 => 'Solar energy',
    23068 => 'Wind power',
    23069 => 'Ocean power',
    23070 => 'Biomass',
    23081 => 'Energy education/training',
    23082 => 'Energy research',
    24010 => 'Financial policy and administrative management',
    24020 => 'Monetary institutions',
    24030 => 'Formal sector financial intermediaries',
    24040 => 'Informal/semi-formal financial intermediaries',
    24081 => 'Education/training in banking and financial services',
    25010 => 'Business support services and institutions',
    25020 => 'Privatisation',
    31110 => 'Agricultural policy and administrative management',
    31120 => 'Agricultural development',
    31130 => 'Agricultural land resources',
    31140 => 'Agricultural water resources',
    31150 => 'Agricultural inputs',
    31161 => 'Food crop production',
    31162 => 'Industrial crops/export crops',
    31163 => 'Livestock',
    31164 => 'Agrarian reform',
    31165 => 'Agricultural alternative development',
    31166 => 'Agricultural extension',
    31181 => 'Agricultural education/training',
    31182 => 'Agricultural research',
    31191 => 'Agricultural services',
    31192 => 'Plant and post-harvest protection and pest control',
    31193 => 'Agricultural financial services',
    31194 => 'Agricultural co-operatives',
    31195 => 'Livestock/veterinary services',
    31210 => 'Forestry policy and administrative management',
    31220 => 'Forestry development',
    31261 => 'Fuelwood/charcoal',
    31281 => 'Forestry education/training',
    31282 => 'Forestry research',
    31291 => 'Forestry services',
    31310 => 'Fishing policy and administrative management',
    31320 => 'Fishery development',
    31381 => 'Fishery education/training',
    31382 => 'Fishery research',
    31391 => 'Fishery services',
    32110 => 'Industrial policy and administrative management',
    32120 => 'Industrial development',
    32130 => 'Small and medium-sized enterprises (SME) development',
    32140 => 'Cottage industries and handicraft',
    32161 => 'Agro-industries',
    32162 => 'Forest industries',
    32163 => 'Textiles, leather and substitutes',
    32164 => 'Chemicals',
    32165 => 'Fertilizer plants',
    32166 => 'Cement/lime/plaster',
    32167 => 'Energy manufacturing',
    32168 => 'Pharmaceutical production',
    32169 => 'Basic metal industries',
    32170 => 'Non-ferrous metal industries',
    32171 => 'Engineering',
    32172 => 'Transport equipment industry',
    32182 => 'Technological research and development',
    32210 => 'Mineral/mining policy and administrative management',
    32220 => 'Mineral prospection and exploration',
    32261 => 'Coal',
    32262 => 'Oil and gas',
    32263 => 'Ferrous metals',
    32264 => 'Nonferrous metals',
    32265 => 'Precious metals/materials',
    32266 => 'Industrial minerals',
    32267 => 'Fertilizer minerals',
    32268 => 'Offshore minerals',
    32310 => 'Construction policy and administrative management',
    33110 => 'Trade policy and administrative management',
    33120 => 'Trade facilitation',
    33130 => 'Regional trade agreements (RTAs)',
    33140 => 'Multilateral trade negotiations',
    33150 => 'Trade-related adjustment',
    33181 => 'Trade education/training',
    33210 => 'Tourism policy and administrative management',
    41010 => 'Environmental policy and administrative management',
    41020 => 'Biosphere protection',
    41030 => 'Bio-diversity',
    41040 => 'Site preservation',
    41050 => 'Flood prevention/control',
    41081 => 'Environmental education/ training',
    41082 => 'Environmental research',
    43010 => 'Multisector aid',
    43030 => 'Urban development and management',
    43040 => 'Rural development',
    43050 => 'Non-agricultural alternative development',
    43081 => 'Multisector education/training',
    43082 => 'Research/scientific institutions',
    51010 => 'General budget support',
    52010 => 'Food aid/Food security programmes',
    53030 => 'Import support (capital goods)',
    53040 => 'Import support (commodities)',
    60010 => 'Action relating to debt',
    60020 => 'Debt forgiveness',
    60030 => 'Relief of multilateral debt',
    60040 => 'Rescheduling and refinancing',
    60061 => 'Debt for development swap',
    60062 => 'Other debt swap',
    60063 => 'Debt buy-back',
    72010 => 'Material relief assistance and services',
    72040 => 'Emergency food aid',
    72050 => 'Relief co-ordination; protection and support services',
    73010 => 'Reconstruction relief and rehabilitation',
    74010 => 'Disaster prevention and preparedness',
    91010 => 'Administrative costs',
    92010 => 'Support to national NGOs',
    92020 => 'Support to international NGOs',
    92030 => 'Support to local and regional NGOs',
    93010 => 'Refugees in donor countries',
    99810 => 'Sectors not specified',
    99820 => 'Promotion of development awareness'
  }

  def transaction_type(code)
    @@transaction_types[code]
  end

  def transaction_title(code)
      @@transaction_titles[code]
  end

  def activity_status(code)
    @@activity_statuses[code]
  end

  def mime_type(code)
    @@mime_types[code]
  end

  def sector(code)
    @@sectors[code]
  end

  def location_type(code)
    @@location_type[code]
  end

  def global_recipients(code)
    @@global_recipients[code]
  end

  def geographical_precision(code) 
    @@geographical_precision[code]
  end

  def self.all_global_recipients
    @@global_recipients
  end

  module_function :location_type
  module_function :geographical_precision

end