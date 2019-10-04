puts "*"*80
puts "::: Generating Carriers:::"

hbx_office = OfficeLocation.new(
    is_primary: true, 
    address: {kind: "work", address_1: "address_placeholder", address_2: "609 H St, Room 415", city: "Washington", state: "DC", zip: "20002" }, 
    phone: {kind: "main", area_code: "202", number: "555-1212"}
  )

org = Organization.new(office_locations: [hbx_office], fein: "010000000", legal_name: "Delta Dental")
cp = org.create_carrier_profile(id: "53e67210eb899a4603000010", abbrev: "DDPA", hbx_carrier_id: "116173", ivl_health: false, ivl_dental: true, shop_health: false, shop_dental: false)

org = Organization.new(office_locations: [hbx_office], fein: "020000000", legal_name: "Dentegra")
cp = org.create_carrier_profile(id: "53e67210eb899a4603000013", abbrev: "DTGA", hbx_carrier_id: "116180", ivl_health: false, ivl_dental: true, shop_health: false, shop_dental: false)

org = Organization.new(office_locations: [hbx_office], fein: "030000000", legal_name: "Independence")
cp = org.create_carrier_profile(id: "53e67210eb899a4603000016", abbrev: "DMND", hbx_carrier_id: "116184", ivl_health: false, ivl_dental: true, shop_health: false, shop_dental: false)

org = Organization.new(office_locations: [hbx_office], fein: "050000000", legal_name: "PA Health Wellness")
cp = org.create_carrier_profile(id: "53e67210eb899a460300001a", abbrev: "BLHI", hbx_carrier_id: nil, ivl_health: false, ivl_dental: false, shop_health: false, shop_dental: false)

org = Organization.new(office_locations: [hbx_office], fein: "060000000", legal_name: "Independence")
cp = org.create_carrier_profile(id: "53e67210eb899a460300001d", abbrev: "META", hbx_carrier_id: nil, ivl_health: false, ivl_dental: false, shop_health: false, shop_dental: false)

org = Organization.new(office_locations: [hbx_office], fein: "070000000", legal_name: "UPMC Health Plan")
cp = org.create_carrier_profile(id: "53e67210eb899a4603000004", abbrev: "GHMSI", hbx_carrier_id: "116036", ivl_health: true, ivl_dental: false, shop_health: true, shop_dental: false)

org = Organization.new(office_locations: [hbx_office], fein: "080000000", legal_name: "Oscar")
cp = org.create_carrier_profile(id: "53e67210eb899a4603000007", abbrev: "AHI", hbx_carrier_id: "116163", ivl_health: true, ivl_dental: false, shop_health: true, shop_dental: false)

org = Organization.new(office_locations: [hbx_office], fein: "090000000", legal_name: "Highmark")
cp = org.create_carrier_profile(id: "53e67210eb899a460300000a", abbrev: "UHIC", hbx_carrier_id: "116034", ivl_health: false, ivl_dental: false, shop_health: true, shop_dental: false)

org = Organization.new(office_locations: [hbx_office], fein: "001000000", legal_name: "Keystone")
cp = org.create_carrier_profile(id: "53e67210eb899a460300000d", abbrev: "KFMASI", hbx_carrier_id: "116028", ivl_health: true, ivl_dental: false, shop_health: true, shop_dental: false)


puts "::: Carriers Complete :::"
puts "*"*80
