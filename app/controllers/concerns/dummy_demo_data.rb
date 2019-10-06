class DummyDemoData
    attr_reader :person, :model, :primary_predefined, :dependent_predefined

    def initialize(person:, model:)
        @person = person
        @model = model
        @primary_predefined = open_primary_file
        @dependent_predefined = open_dependent_file
    end

    def mock_data
        coverage_year = @person.primary_family.application_applicable_year
        @model.update_attributes!(aasm_state: "determined", assistance_year: coverage_year, determination_http_status_code: 200)
        @model.tax_households.each do |txh|
            txh.update_attributes!(allocated_aptc: all_aptc, is_eligibility_determined: eligibility_det, effective_starting_on: Date.new(coverage_year, 01, 01))
            txh.eligibility_determinations.build(
                max_aptc: max_aptc,
                csr_percent_as_integer: csr_int,
                csr_eligibility_kind: csr_kind,
                determined_on: TimeKeeper.datetime_of_record - 30.days,
                determined_at: TimeKeeper.datetime_of_record - 30.days,
                premium_credit_strategy_kind: "allocated_lump_sum_credit",
                e_pdc_id: "3110344",
                source: "Haven").save!
            txh.applicants.each do |applicant|
                applicant.update_attributes!(
                    is_medicaid_chip_eligible: medicaid?(applicant), 
                    is_ia_eligible: ia_elig?(applicant), 
                    is_without_assistance: no_assistance?(applicant))
            end
            @model.applicants.each do |applicant|
                applicant.update_attributes!(:assisted_income_validation => 'outstanding', :assisted_mec_validation => 'outstanding', aasm_state: "verification_outstanding")
                applicant.verification_types.each { |verification| verification.update_attributes!(validation_status: 'outstanding') }
            end
        end
    end

    private

    def medicaid?(applicant)
        dependent(applicant).present? ? dependent['is_medicaid_chip_eligible'] : false
    end

    def ia_elig?(applicant)
        dependent(applicant).present? ? dependent['is_ia_eligible'] : false
    end

    def no_assistance?(applicant)
        dependent(applicant).present? ? dependent['is_without_assistance'] : true
    end


    def all_aptc
        primary.present? ? primary['allocated_aptc'] : 200.00
    end

    def max_aptc
        primary.present? ? primary['max_aptc'] : 200.00
    end

    def eligibility_det
        primary.present? ? primary['is_eligibility_determined'] : true
    end

    def csr_int
        primary.present? ? primary['csr_percent'] : 73
    end

    def csr_kind
        primary.present? ? primary['csr_eligibility_kind'] : "csr_73"
    end



    def primary
        primary_predefined.find{|p| p['first_name'] == person.first_name && p['last_name'] == person.last_name}
    end

    def dependent(applicant)
        dependent_predefined.find{|p| p['first_name'] == applicant.person.first_name && p['last_name'] == applicant.person.last_name}
    end

    def open_primary_file
        file_user = File.open("db/faa_core_seedfiles/faa_primary_mock_demo.json", "r")
        subscribers = file_user.read
        file_user.close
        JSON.load(subscribers)
    end

    def open_dependent_file
        file_user = File.open("db/faa_core_seedfiles/faa_applicant_mock_demo.json", "r")
        dependents = file_user.read
        file_user.close
        JSON.load(dependents)
    end
end
