renewal_feins = ["522139122", "472574696", "521746328", "521553060", "521967481", "463553978", "462945820", "271713532", "237000150", "521481003", "465441879", "464327434", "521575658", "522332161", "521853388", "472448373", "473989731", "411398118", "264553787", "200763349", "611521377", "461368721", "462231413", "461593541", "262347256", "521611993", "830469770", "455527711", "562325097", "237200739", "521821935", "453156794", "464614572", "473974806", "342052507", "463995547", "521812360", "465019387", "471277957", "522125232", "464721526", "463662061", "631044781", "520858001", "520984255", "521547845", "208624702", "953750694", "521935342", "200529671", "473252386", "522277650", "530163480", "472577579", "521220223", "461625412", "452828830", "204690417", "522359517", "521743817", "637348238", "521766832", "473437657", "471118215", "364476244"]
conversion_feins =["521131199", "455373892", "203977558", "020769309", "134249543", "521764344", "999999995", "520781390", "521231983", "530196567", "870745629", "132581875", "520845718", "202305292", "264442148", "326166948", "362340300", "200915207", "521091718", "941450490", "942763845", "133914342", "202926200", "522032499", "273175119", "202990791", "522289343", "581557556", "530191635", "273980558", "522334463", "204865805", "271976324", "260832862", "020785811", "954163931", "202187349", "521282103", "311766444", "264127579", "522321361", "520941367", "521644571", "530207408", "521633220", "261799321", "530258392", "264094042", "521173228", "520966285", "042992565", "521239804", "530078064", "521629385", "470975519", "530259978", "711019574", "208146088", "261392682", "522075691", "521891162", "364778585", "521088411", "521854633", "201799842", "261607955", "237218916", "000000031", "134229575", "521385018", "300168697", "264787596", "522077951", "521428669", "000000029", "000000023", "084462763", "455616367", "521979573", "237185827", "462416858", "263987744", "522228944", "943438751", "521602643", "530210664", "263155690", "432017324", "522141499", "262903088", "522003122", "521929169", "260126537", "711045354", "202130493", "521793723", "260077227", "522250839", "273443167", "521909847", "203380456", "000000024", "262113110", "522202731", "260204031", "542073913", "521298659", "273281915", "521925788", "521164983", "521104567", "521594479", "521447196", "520986261", "202700607", "133711840", "421693698", "541487512", "521690303", "810635596", "331096765", "521168827", "200118307", "454026252", "521807436", "522279789", "451657406", "263463204", "611558833", "521782312", "421719040", "522287851", "521768183", "530259837", "363832940", "237451661", "911568650", "953927141", "521218832", "522086855", "237347351", "135544472", "521268692", "521473117", "530182304", "237447365", "522005999", "272942781", "520909444", "541748419", "521740146", "521586114", "463346460", "522013356", "541719573", "870803909", "942716768", "261126743", "453836904", "521687743", "522165679", "522071979", "520899578", "223980819", "520939363", "300480309", "530204690", "371635320", "520986797", "204073133", "521792575", "541935838", "200799914", "521209527", "264032886", "541824478", "264573463", "520858068", "521666904", "452398600", "020767157", "621440640", "521954273", "237367533", "521474935", "521471376", "521104809", "900436782", "521684389", "261715929", "273369694", "521473769", "526046203", "330147824", "237147887", "530224276", "465096233", "521505364", "205258714", "520807696", "202037984", "521905865", "521279682", "521557819", "521480202", "130615840", "521645512", "521722025", "200482817", "520741350", "202458375", "202468102", "521801489", "208446765", "541965828", "452375150", "363976313", "521294659", "542051425", "541394025", "522217020", "900536785", "521156410", "522336694", "522181533", "521380506", "471109600", "521209825", "043677636", "522100597", "521323437"]
initial_feins = ["451431314", "274551672", "273208144", "200457331", "811095280", "205150809", "812341035", "320397845", "000000011", "263412575", "454028722", "980227419", "472482633", "473089352", "475031574", "522007895", "274415158", "521541060", "050373312", "410976048", "811160808", "454495950", "460988928", "474325410", "201115618", "530225257", "811397590", "475437882", "010860025", "810971614", "273067305", "611690874", "364827426", "203235972"]


def write_to_csv(type, feins)
  dir = "ga_files"

  Dir.mkdir(dir) unless File.exists?(dir)

  csv_hash = {}

  feins.each do |fein|
    org = Organization.where(fein: fein).first

    if org.nil?
      puts "#{fein} Organization not found"
      next
    end

    employer = org.employer_profile

    if employer.active_general_agency_account.nil?
      next
    end

    carriers = employer.plan_years.select(&:eligible_for_export?).flat_map(&:benefit_groups).flat_map(&:elected_plans).flat_map(&:carrier_profile).uniq! || []

    carriers.each do |carrier|
      csv_hash[carrier.legal_name] = [] if csv_hash[carrier.legal_name].nil?

      csv_hash[carrier.legal_name] << [employer.legal_name, employer.hbx_id, employer.fein,
                                       (employer.active_broker_agency_account.writing_agent.person.full_name rescue ("")),
                                       (employer.active_broker_agency_account.writing_agent.npn rescue ("")),
                                       employer.active_general_agency_account.legal_name,
                                       (employer.active_general_agency_account.broker_role_name rescue ("")),
                                       (employer.active_general_agency_account.broker_role.npn rescue ("")),
                                       (employer.active_general_agency_account.general_agency_profile.fein rescue (""))]
    end
  end

  csv_hash.each do |carrier, csv_rows|
    csv = CSV.open(dir + "/" + "#{carrier}_#{type}.csv", "wb")
    csv << %w[employer.legal_name, employer.hbx_id, employer.fein,
          employer.active_broker_agency_account.writing_agent.person.full_name,
          employer.active_broker_agency_account.writing_agent.npn,
          active_general_agency_account.legal_name,
          active_general_agency_account.broker_role_name,
          active_general_agency_account.broker_role.npn,
          active_general_agency_account.general_agency_profile.fein]

    csv_rows.each do |row|
      csv << row
    end
  end
end


write_to_csv("renewal", renewal_feins)
write_to_csv("conversion", conversion_feins)
write_to_csv("initial", initial_feins)