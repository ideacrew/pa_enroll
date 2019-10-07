require 'mongo'
require 'csv'
require 'pp'
require 'securerandom'

class OpmSeed

  def initialize
    @ee_count = {}
    @age_codes = {
      "A" => young,
      "B" => twenty,
      "C" => twenty_five,
      "D" => thirty,
      "E" => thirty_five,
      "F" => forty,
      "G" => forty_five,
      "H" => fifty,
      "I" => fifty_five,
      "J" => sixty,
      "K" => sixty_five,
      'Z' => old }
    @agency_codes = {}
    @ee_count_mapping = {}
    @eps = Organization.all.map(&:employer_profile).compact.map(&:id)
    @org_cache =  ActiveSupport::Cache::MemoryStore.new
    @people = []
    @families = []
    @ces = []

    #@client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'pa_enroll_development')
    @client = Mongo::Client.new([ '172.30.1.56:27017' ], :database => 'enroll_ct_ivl', auth_source: 'admin', user:'admin', password:'enrUAT7102*@!')
  end

  def time_rand from = 0.0, to = Time.now
    Time.at(from + rand * (to.to_f - from.to_f))
  end

  def young
    time_rand (Time.now - 1.years ),(Time.now - 20.years)
  end

  def twenty
    time_rand (Time.now - 20.years),(Time.now - 24.years)
  end

  def twenty_five
    time_rand (Time.now - 25.years),(Time.now - 29.years)
  end

  def thirty
    time_rand (Time.now - 30.years),(Time.now - 34.years)
  end

  def thirty_five
    time_rand (Time.now - 35.years),(Time.now - 39.years)
  end

  def forty
    time_rand (Time.now - 40.years),(Time.now - 44.years)
  end

  def forty_five
    time_rand (Time.now - 45.years),(Time.now - 49.years)
  end

  def fifty
    time_rand (Time.now - 50.years),(Time.now - 54.years)
  end

  def fifty_five
    time_rand (Time.now - 55.years),(Time.now - 59.years)
  end

  def sixty
    time_rand (Time.now - 60.years),(Time.now - 64.years)
  end

  def sixty_five
    time_rand (Time.now - 65.years),(Time.now - 69.years)
  end

  def old
    time_rand (Time.now - 20.years),(Time.now - 80.years)
  end


  def get_ssn
    @ssn||= "0000111"
    @ssn = @ssn.next
    ssn =  "00#{@ssn}"
    Person.encrypt_ssn(ssn)
  end

  def get_gender
    ["male","female"].sample
  end

  def get_hbx_id
    @hbx_id ||= '21000001'
    @hbx_id = @hbx_id.next
    ssn =  "#{@hbx_id.to_s}"
  end


  def spouse_only(age,name_0,name_1,name_2,family_id_0,family_id_1,status)
    family_member_id_0 = BSON::ObjectId.new
    family_member_id_1 = BSON::ObjectId.new
    family_member_id_2 = BSON::ObjectId.new
    # counter = ln

    p0_id =  BSON::ObjectId.new
    p2_id = BSON::ObjectId.new

    p0_dob = Date.new(rand(1950..1990), rand(1..12), rand(1..28))
    p0_first_name = Faker::Name.first_name
    p0_last_name = Faker::Name.last_name
    p0 = {
      "_id" => p0_id,
      "alternate_name"=>nil,
      "broker_agency_contact_id"=>nil,
      "created_at"=>nil,
      "date_of_death"=>nil,
      "dob"=> p0_dob,
      "dob_check"=>nil,
      "employer_contact_id"=>nil,
      "encrypted_ssn"=> get_ssn,
      "person_relationships"=>
      [{"_id"=>BSON::ObjectId.new,
        "created_at"=>nil,
        "kind"=>"spouse",
        "updated_at"=>nil,
        "predecessor_id" => p2_id,
        "successor_id"=> p0_id,
        "family_id" => family_id_0}
      ],
      "ethnicity"=>nil,
      "first_name"=>p0_first_name,
      "full_name"=>"#{p0_first_name} #{p0_last_name}",
      "gender"=>get_gender,
      "general_agency_contact_id"=>nil,
      "hbx_id"=>get_hbx_id,
      "is_active"=>true,
      "is_disabled"=>nil,
      "is_homeless"=>false,
      "is_incarcerated"=>nil,
      "is_physically_disabled"=>nil,
      "is_temporarily_out_of_state"=>false,
      "is_tobacco_user"=>"unknown",
      "language_code"=>nil,
      "last_name"=>p0_last_name,
      "middle_name"=>nil,
      "modifier_id"=>nil,
      "name_pfx"=>nil,
      "name_sfx"=>nil,
      "no_dc_address"=>false,
      "no_ssn"=>nil,
      "race"=>nil,
      "tracking_version"=>1,
      "tribal_id"=>nil,
      "updated_at"=>nil,
      "updated_by"=>nil,
      "updated_by_id"=>nil,
      "consumer_role"=> nil,
      "version"=>1}

    p2_dob = Date.new(rand(1950..1990), rand(1..12), rand(1..28))
    p2_first_name = Faker::Name.first_name
    p2 = {
      "_id" => p2_id,
      "alternate_name"=>nil,
      "broker_agency_contact_id"=>nil,
      "created_at"=>nil,
      "date_of_death"=>nil,
      "dob"=> p2_dob,
      "dob_check"=>nil,
      "employer_contact_id"=>nil,
      "encrypted_ssn"=>get_ssn,
      "ethnicity"=>nil,
      "first_name"=>p2_first_name,
      "full_name"=>"#{p2_first_name} #{p0_last_name}",
      "gender"=>get_gender,
      "general_agency_contact_id"=>nil,
      "hbx_id"=>get_hbx_id,
      "person_relationships"=>
      [{"_id"=>BSON::ObjectId.new,
        "created_at"=>nil,
        "kind"=>"spouse",
        "updated_at"=>nil,
        "predecessor_id" =>p2_id,
        "successor_id"=> p0_id,
        "family_id" => family_id_0}],
        "is_active"=>true,
        "is_disabled"=>nil,
        "is_homeless"=>false,
        "is_incarcerated"=>nil,
        "is_physically_disabled"=>nil,
        "is_temporarily_out_of_state"=>false,
        "is_tobacco_user"=>"unknown",
        "language_code"=>nil,
        "last_name"=>p0_last_name,
        "middle_name"=>nil,
        "modifier_id"=>nil,
        "name_pfx"=>nil,
        "name_sfx"=>nil,
        "no_dc_address"=>false,
        "no_ssn"=>nil,
        "race"=>nil,
        "tracking_version"=>1,
        "tribal_id"=>nil,
        "updated_at"=>nil,
        "updated_by"=>nil,
        "updated_by_id"=>nil,
        "user_id"=> get_hbx_id,
        "consumer_roles"=> nil,
        "version"=>1}






    # @client[:people].insert_one p3

    # @client[:census_members].insert_one @ce_0
    # @client[:census_members].insert_one @ce_1



    fam = {
      "_id" => family_id_0,
      "application_type"=>nil,
      "created_at"=>nil,
      "e_case_id"=>nil,
      "e_status_code"=>nil,
      "family_members"=>
      [{ "_id" => family_member_id_0,
         "broker_role_id"=>nil,
         "created_at"=>nil,
         "former_family_id"=>nil,
         "is_active"=>true,
         "is_consent_applicant"=>false,
         "is_coverage_applicant"=>true,
         "is_primary_applicant"=>true,
         "person_id"=> p0['_id'],
         "_type"=>"FamilyMember",
         "updated_at"=>nil,
         "updated_by_id"=>nil},
         { "_id" => family_member_id_1,
           "broker_role_id"=>nil,
           "created_at"=>nil,
           "former_family_id"=>nil,
           "is_active"=>true,
           "is_consent_applicant"=>false,
           "is_coverage_applicant"=>true,
           "is_primary_applicant"=>false,
           "person_id"=> p2['_id'],
           "_type"=>"FamilyMember",
           "updated_at"=>nil,
           "updated_by_id"=>nil}
      ],
      "haven_app_id"=>nil,
      "hbx_assigned_id"=>10002,
      "households"=>
      [{    "_id" => BSON::ObjectId.new,
            "coverage_households"=>
      [{    "_id" => BSON::ObjectId.new,
            "aasm_state"=>"applicant",
            "broker_agency_id"=>nil,
            "coverage_household_members"=>
      [{    "_id" => BSON::ObjectId.new,
            "created_at"=>nil,
            "family_member_id"=> family_member_id_0,
            "is_subscriber"=>true,
            "updated_at"=>nil },
            {    "_id" => BSON::ObjectId.new,
                 "created_at"=>nil,
                 "family_member_id"=> family_member_id_1,
                 "is_subscriber"=>false,
                 "updated_at"=>nil },

      ],
      "created_at"=>nil,
      "is_determination_split_household"=>false,
      "is_immediate_family"=>true,
      "submitted_at"=>nil,
      "updated_at"=>nil,
      "updated_by_id"=>nil,
      "writing_agent_id"=>nil},
      {"_id"=>BSON::ObjectId.new,
       "aasm_state"=>"applicant",
       "broker_agency_id"=>nil,
       "created_at"=>nil,
       "is_determination_split_household"=>false,
       "is_immediate_family"=>false,
       "submitted_at"=>nil,
       "updated_at"=>nil,
       "updated_by_id"=>nil,
       "writing_agent_id"=>nil}],
       "created_at"=>nil,
       "effective_ending_on"=>Date.new(2020,5,5),
       "effective_starting_on"=>Date.new(2019,5,6),
       "irs_group_id"=>BSON::ObjectId.new,
       "is_active"=>true,
       "submitted_at"=>nil,
       "updated_at"=>nil,
       "updated_by_id"=>nil}],
       "irs_groups"=>
      [{"_id"=>BSON::ObjectId.new,
        "created_at"=>nil,
        "effective_ending_on"=>Date.new(2020,5,5),
        "effective_starting_on"=>Date.new(2020,5,5),
        "hbx_assigned_id"=>nil,
        "is_active"=>true,
        "updated_at"=>nil,
        "updated_by_id"=>nil}],
        "is_active"=>true,
        "is_applying_for_assistance"=>nil,
        "min_verification_due_date"=>nil,
        "person_id"=>nil,
        "renewal_consent_through_year"=>nil,
        "status"=>"",
        "submitted_at"=>nil,
        "updated_at"=>nil,
        "updated_by"=>nil,
        "updated_by_id"=>nil,
        "version"=>1,
        "vlp_documents_status"=>nil}

    @people.push(p0, p2)
    puts @people.inspect
    # @ces.push(@ce_0, @ce_10)
    @families.push(fam)
    db_dump
  end

  def db_dump
    @people.each do |person|
      @client[:people].insert_one person
    end
    #@people = @people.map { |person| { insert_one: person } }
    #@client[:people].insert_many @people
    #@families = @families.map { |family| { insert_one: family } }
    puts "families: #{@client[:families].insert_many @families}"
    # @ces = @ces.map { |ce| { insert_one: ce } }
    # @client[:census_members].insert_many @ces
    @people = []
    @families = []
    @ces = []
  end




  def build_people
    Mongo::Logger.logger.level = ::Logger::FATAL
    puts "********************************* Opm person seed started at #{Time.now} ********************************* "
    @counter = 0
    @sampler = 0

    while @counter < 1200000 do
      puts 'beginning of loop'
      # CSV.foreach("db/seedfiles/opm_people.csv", :headers => true).with_index(1)  do |row,ln|
      # org = Organization.where(dba: @agency_codes[row[0]][0]).first
      # ep =  org.employer_profile//
      name_0 = Faker::Name.name
      name_1 = Faker::Name.name
      name_2 = Faker::Name.name
      name_3 = Faker::Name.name
      name_4 = Faker::Name.name
      name_5 = Faker::Name.name
      name_6 = Faker::Name.name
      name_7 = Faker::Name.name
      name_8 = Faker::Name.name
      name_9 = Faker::Name.name
      family_id_0 = BSON::ObjectId.new
      family_id_1 = BSON::ObjectId.new
      family_id_2 = BSON::ObjectId.new
      family_id_3 = BSON::ObjectId.new

      spouse_only(1,name_8,name_9,name_0,family_id_2,family_id_3,"active")
      puts @counter.inspect
      @counter += 1
      puts @counter.inspect
    end

    puts "********************************* OPM person seed completed at #{Time.now} ********************************* "

  end
end

seed = OpmSeed.new

# seed.build_orgs
seed.build_people


# Organization.all.each do |org|
#     org.update_attributes(hbx_id: HbxIdGenerator.generate_organization_id)
# end
