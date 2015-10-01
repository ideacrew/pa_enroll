class CensusEmployeeImport
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :file, :employer_profile

  TEMPLATE_DATE = Date.new(2015, 9, 6)
  TEMPLATE_VERSION = "1.0"
  TEMPLATE_DATE_CELL = 7
  TEMPLATE_VERSION_CELL = 13

  MEMBER_RELATIONSHIP_KINDS = %w(employee spouse domestic_partner child)

  CENSUS_MEMBER_RECORD = %w(
      employer_assigned_family_id 
      employee_relationship
      last_name 
      first_name 
      middle_name 
      name_sfx
      email 
      ssn 
      dob 
      gender
      hire_date 
      termination_date
      is_business_owner
      benefit_group
      plan_year
    )

  CENSUS_MEMBER_RECORD_TITLES = [
      "Family ID #(to match family members to the EE)",
      "Relationship(EE, Spouse, Domestic Partner, or Child)",
      "Last Name",
      "First Name",
      "Middle Name or Initial(optional)",
      "Suffix(optional)",
      "Email Address",
      "SSN / TIN(Required for EE)",
      "Date of Birth",
      "Gender",
      "Date of Hire",
      "Date of Termination(optional)",
      "Is Business Owner?",
      "Benefit Group(optional)",
      "Plan Year(Optional)"
  ]

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }

    raise ArgumentError, "Must provide an import file" unless defined?(@file)
    raise ArgumentError, "Must provide an EmployerProfile" unless defined?(@employer_profile)
  end

  def persisted?
    false
  end

  def imported_census_employees
    @imported_census_employees ||= load_imported_census_employees
  end

  def load_imported_census_employees
    # file = 'spec/test_data/spreadsheet_templates/DCHL Employee Census.xlsx'
    roster = Roo::Spreadsheet.open(@file.tempfile.path)

    @sheet = roster.sheet(0)
    @last_ee_member = {}

    # To match spreadsheet convention, Roo gem uses 1-based (rather than 0-based) references 
    # First three rows are header content
    sheet_header_row = @sheet.row(1)
    column_header_row = @sheet.row(2)
    # label_header_row  = @sheet.row(3)

    unless header_valid?(sheet_header_row) && column_header_valid?(column_header_row)
      raise "Unrecognized Employee Census spreadsheet format. Contact DC Health Link for current template."
    end

    census_employees = []
    (4..@sheet.last_row).map do |i|
      row = Hash[[column_header_row, roster.row(i)].transpose]
      record = parse_row(row)
      break if record[:employer_assigned_family_id].nil?
      if record[:termination_date].present?
        census_employee = terminate_employee(record)
      else
        census_employee = add_or_update_census_member(record)
      end

      census_employee ||= nil
      census_employees << census_employee
    end
    census_employees
  end

  def terminate_employee(record)
    employee = CensusEmployee.find_by_employer_profile(@employer_profile).by_ssn(record[:ssn]).active.first
    if employee.present?
      employee.terminate_employment(record[:termination_date])
      employee.save
      #employee = CensusEmployee.find_by_employer_profile(@employer_profile).by_ssn(record[:ssn]).terminated.order(:employment_terminated_on.desc).first
    end
    employee
  end

  # change attributes, add or remove dependents
  def add_or_update_census_member(record)
    # Process Employee
    if record[:employee_relationship].downcase == "self"
      member = CensusEmployee.find_by_employer_profile(@employer_profile).by_ssn(record[:ssn]).active.first || CensusEmployee.new
      member = assign_census_employee_attributes(member, record)
      member.terminate_employment(member.employment_terminated_on) if member.employment_terminated_on.present?
      @last_ee_member = member
    else
      # Process dependent
      if record[:employer_assigned_family_id] == @last_ee_member[:employer_assigned_family_id]
        member = census_dependent
      end
    end

    member ||= nil
  end

  def assign_census_employee_attributes(member, record)
    member.ssn = record[:ssn].to_s if record[:ssn]
    member.first_name = record[:first_name].to_s if record[:first_name]
    member.last_name = record[:last_name].to_s if record[:last_name]
    member.middle_name = record[:middle_initial].to_s if record[:middle_initial]
    member.name_sfx = record[:name_sfx].to_s if record[:name_sfx]
    member.dob = record[:dob].to_s if record[:dob]
    member.hired_on = record[:hire_date] if record[:hire_date]
    if ["0", "false"].include? record[:is_business_owner].to_s
      member.is_business_owner = false
    else
      member.is_business_owner = true
    end
    member.gender = record[:gender].to_s if record[:gender]
    member.email = Email.new({address: record[:email].to_s, kind: "home"}) if record[:email]
    member.employee_relationship = record[:employee_relationship].to_s if record[:employee_relationship]
    member.employer_profile = @employer_profile
    assign_benefit_group(member, record[:benefit_group], record[:plan_year])
    member
  end

  def assign_benefit_group(member, benefit_group, plan_year)
    plan_year_found = @employer_profile.plan_years.detect do |py|
      py.start_on.year.to_s == plan_year
    end
    return if plan_year_found.nil?
    benefit_group_found = plan_year_found.benefit_groups.detect do |bg|
      bg.title == benefit_group
    end
    return if benefit_group_found.nil?
    member.benefit_group_assignments << BenefitGroupAssignment.new({benefit_group_id: benefit_group_found.id , start_on: plan_year_found.start_on})
  end

  def parse_row(row)
    employer_assigned_family_id = parse_text(row["employer_assigned_family_id"])
    employee_relationship = parse_relationship(row["employee_relationship"])
    last_name = parse_text(row["last_name"])
    first_name = parse_text(row["first_name"])
    middle_initial = parse_text(row["middle_initial"])
    name_sfx = parse_text(row["name_sfx"])
    email = parse_text(row["email"])
    ssn = parse_ssn(row["ssn"])
    dob = parse_date(row["dob"])
    gender = parse_text(row["gender"])
    hire_date = parse_date(row["hire_date"])
    termination_date = parse_date(row["termination_date"])
    is_business_owner = parse_boolean(row["is_business_owner"])
    benefit_group = parse_text(row["benefit_group"])
    plan_year = parse_text(row["plan_year"])

    {
        employer_assigned_family_id: employer_assigned_family_id,
        employee_relationship: employee_relationship,
        last_name: last_name,
        first_name: first_name,
        middle_initial: middle_initial,
        name_sfx: name_sfx,
        email: email,
        ssn: ssn,
        dob: dob,
        gender: gender,
        hire_date: hire_date,
        termination_date: termination_date,
        is_business_owner: is_business_owner,
        benefit_group: benefit_group,
        plan_year: plan_year
    }
  end

  def header_valid?(sheet_header_row)
    if sheet_header_row[TEMPLATE_DATE_CELL].is_a? Date
      template_date = sheet_header_row[TEMPLATE_DATE_CELL]
    else
      template_date = Date.strptime(sheet_header_row[TEMPLATE_DATE_CELL], "%m/%d/%Y" )
    end
    template_date == TEMPLATE_DATE &&
    sheet_header_row[TEMPLATE_VERSION_CELL] == TEMPLATE_VERSION
  end

  def column_header_valid?(column_header_row)
    clean_header = column_header_row.reduce([]) { |memo, header_text| memo << sanitize_value(header_text) }
    clean_header == CENSUS_MEMBER_RECORD
  end

  def parse_relationship(cell)
    # defined? @last_employer_assigned_family_id ? 
    return nil if cell.blank?
    field_map = case parse_text(cell).downcase
                  when "employee"
                    "self"
                  when "spouse"
                    "spouse"
                  when "domestic partner"
                    "domestic_partner"
                  when "child"
                    "child"
                  when "disabled child"
                    "disabled_child"
                  else
                    nil
                end

    field_map
  end

  def parse_text(cell)
    cell.blank? ? nil : sanitize_value(cell)
  end

  def parse_date(cell)
    return nil if cell.blank?
    return DateTime.strptime(cell.sanitize_value, "%d/%m/%Y") rescue raise ImportErrorValue, cell if cell.class == String
    return cell.to_s.sanitize_value.to_time.strftime("%m-%d-%Y") rescue raise ImportErrorDate, cell if cell.class == String
    # return cell.sanitize_value.to_date.to_s(:db) rescue raise ImportErrorValue, cell if cell.class == String

    cell.blank? ? nil : cell
  end

  def parse_ssn(cell)
    cell.blank? ? nil : cell.to_s.gsub(/\D/, '')
  end

  def parse_boolean(cell)
    cell.blank? ? nil : cell.match(/(true|t|yes|y|1)$/i) != nil ? "1" : "0"
  end

  def self.parse_boolean(cell)
    cell.blank? ? nil : cell.match(/(true|t|yes|y|1)$/i) != nil ? "1" : "0"
  end

  def self.parse_number(cell)
    cell.blank? ? nil : (Float(cell) rescue raise ImportErrorValue, cell)
  end

  def self.parse_integer(cell)
    cell.blank? ? nil : (Integer(cell) rescue raise ImportErrorValue, cell)
  end

  def save
    if imported_census_employees.map(&:valid?).all?
      imported_census_employees.each(&:save!)
      true
    else
      imported_census_employees.each_with_index do |census_employee, index|
        census_employee.errors.full_messages.each do |message|
          errors.add :base, "Row #{index + 2}: #{message}"
        end
      end
      false
    end
  end

  def open_spreadsheet
    case File.extname(file.original_filename)
      when ".csv" then
        Csv.new(file.path, nil, :ignore)
      when ".xls" then
        Excel.new(file.path, nil, :ignore)
      when ".xlsx" then
        Excelx.new(file.path, nil, :ignore)
      else
        raise "Unknown file type: #{file.original_filename}"
    end
  end

  def length
    @imported_census_employees.length
  end

  alias_method :count, :length

  private
  def sanitize_value(value)
    value = value.to_s.split('.')[0] if value.is_a? Float
    value.gsub(/[[:cntrl:]]|^[\p{Space}]+|[\p{Space}]+$/, '')
  end

end

class ImportErrorValue < Exception;
end
class ImportErrorDate < Exception;
end
