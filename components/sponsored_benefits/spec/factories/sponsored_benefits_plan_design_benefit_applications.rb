FactoryGirl.define do
  factory :plan_design_benefit_application, class: 'SponsoredBenefits::BenefitApplications::BenefitApplication' do
    effective_period { TimeKeeper.date_of_record.next_month.beginning_of_month..TimeKeeper.date_of_record.next_month.beginning_of_month.next_year.prev_day }
    open_enrollment_period { TimeKeeper.date_of_record.beginning_of_month..(TimeKeeper.date_of_record.beginning_of_month + 15.days) }

    trait :with_benefit_group do
      after(:create) do |application, evaluator|
        FactoryGirl.create(:sponsored_benefits_benefit_applications_benefit_group, benefit_application: application)
      end
    end
  end
end
