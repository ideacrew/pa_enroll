require 'csv'
#bundle exec rake reports:shop:employers_with_ssn_validation_disabled
#To generate report for all the employers with ssn validation disabled
namespace :reports do
  namespace :shop do

    desc "Employers with SSN validation disabled"
    task :employers_with_ssn_validation_disabled => :environment do

      employers = Organization.exists(employer_profile: true).where(:"employer_profile.no_ssn" => true)

      field_names  = %w(
          employer_legal_name
          hbx_id
          fein
        )

        processed_count = 0

        Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
        file_name = "#{Rails.root}/hbx_report/employers_with_ssn_validation_disabled.csv"

        CSV.open(file_name, "w", force_quotes: true) do |csv|
          csv << field_names
          employers.each do |employer|
            csv << [
                employer.legal_name,
                employer.hbx_id,
                employer.fein

            ]
          end
          processed_count += 1
        end
        puts "List of all the employers with ssn validation disabled #{file_name}"
    end
  end
end
