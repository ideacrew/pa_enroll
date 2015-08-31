FactoryGirl.define do
  factory :consumer_role do
    sequence(:ssn) { |n| "75634863" + "#{n}" }
    dob "01/01/1980"
    gender 'male'
    is_state_resident 'yes'
    citizen_status 'citizen'
    is_incarcerated 'yes'
    is_applicant 'yes'

    vlp_documents {[FactoryGirl.build(:vlp_document)]}

  end

  factory(:consumer_role_person, {class: ::Person}) do
    first_name { Forgery(:name).first_name }
    last_name { Forgery(:name).first_name }
    gender { Forgery(:personal).gender }
    sequence(:ssn, 222222222)
    dob Date.new(1980, 1, 1)
  end


  factory(:consumer_role_object, {class: ::ConsumerRole}) do
    is_applicant true
    person { FactoryGirl.create(:consumer_role_person) }
  end
end
