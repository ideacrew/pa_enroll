module Forms
  class ConsumerCandidate
    include ActiveModel::Model
    include ActiveModel::Validations

    include PeopleNames
    include SsnField
    attr_accessor :gender
    attr_accessor :user_id
    attr_accessor :no_ssn
    validates_presence_of :first_name, :allow_blank => nil
    validates_presence_of :last_name, :allow_blank => nil
    validates_presence_of :gender, :allow_blank => nil
    validates_presence_of :dob
    # include ::Forms::DateOfBirthField
    #include Validations::USDate.on(:date_of_birth)

    validate :does_not_match_a_different_users_person
    validates :ssn,
              length: {minimum: 9, maximum: 9, message: "SSN must be 9 digits"},
              allow_blank: true,
              numericality: true
    validate :dob_not_in_future
    validate :ssn_or_checkbox
    attr_reader :dob

    def ssn_or_checkbox
      if ssn.blank? && no_ssn == "0"
        errors.add(:base, 'Check No SSN box or enter a valid SSN')
      end
    end        

    def dob=(val)
      @dob = Date.strptime(val, "%Y-%m-%d") rescue nil
    end

    def match_person
      if !ssn.blank?
        Person.where({
                       :dob => dob,
                       :encrypted_ssn => Person.encrypt_ssn(ssn)
                   }).first
      else
        Person.where({
                       :dob => dob,
                       :last_name => last_name
                   }).first 
      end
    end

    def does_not_match_a_different_users_person
      matched_person = match_person
      if matched_person.present?
        if matched_person.user.present?
          if matched_person.user.id.to_s != self.user_id.to_s
            errors.add(
                :base,
                "An account already exists for #{first_name} #{last_name}."
            )
          end
        end
      end
      true
    end

    def dob_not_in_future
      if self.dob && self.dob > ::TimeKeeper.date_of_record
        errors.add(
            :dob,
            "#{dob} can't be in the future.")
        self.dob=""
      end
    end

    def persisted?
      false
    end
  end
end