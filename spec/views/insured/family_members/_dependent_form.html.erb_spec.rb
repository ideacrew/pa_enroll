require 'rails_helper'

describe "insured/family_members/_dependent_form.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:consumer_role) { FactoryGirl.create(:consumer_role)}
  let(:user) { FactoryGirl.create(:user, person: person) }
  let(:family) { Family.new }
  let(:family_member) { family.family_members.new }
  let(:dependent) { Forms::FamilyMember.new(family_id: family.id) }

  context "with consumer_role_id" do
    before :each do
      person.consumer_role = consumer_role
      person.save
      sign_in user
      @request.env['HTTP_REFERER'] = 'consumer_role_id'
      allow(person).to receive(:is_consumer_role_active?).and_return true
      assign :person, person
      assign :dependent, dependent
      assign(:support_texts, {support_text_key: "support-text-description"})
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      render "insured/family_members/dependent_form", dependent: dependent, person: person
    end

    it "should have dependent_list area" do
      expect(rendered).to have_selector("li.dependent_list")
    end

    it "should not have required for ssn" do
      expect(rendered).not_to have_selector('input[placeholder="SOCIAL SECURITY *"]')
    end

    it "should display the is_applying_coverage field option" do
      expect(rendered).to match /Does this person need coverage?/
    end

    it "should display the affirmative message" do
      expect(rendered).to match /Even if you don’t want health coverage for yourself, providing your SSN can be helpful since it can speed up the application process. We use SSNs to check income and other information to see who’s eligible for help with health coverage costs./
    end

    it "should have consumer_fields area" do
      expect(rendered).to have_css('#consumer_fields .row:first-child label', text: 'Are you a US Citizen or US National?')
      expect(rendered).to have_selector("div#consumer_fields")
      expect(rendered).to match /Are you a US Citizen or US National/
    end

    it "should have no_ssn input" do
      expect(rendered).to have_selector('input#dependent_no_ssn')
    end

    it "should have no_ssn label" do
      expect(rendered).to have_selector('span.no_ssn')
      expect(rendered).to match /have an SSN/
    end

    it "should have show tribal_container" do
      expect(rendered).to have_selector('div#tribal_container')
      expect(rendered).to have_content('Are you a member of an American Indian or Alaskan Native tribe? *')
    end

    it "should have dependent-address area" do
      expect(rendered).to have_selector("div#dependent-address")
    end

    it "should have required indicator for fields" do

      ["FIRST NAME", "LAST NAME", "DATE OF BIRTH"].each do |field|
        expect(rendered).to have_selector("input[placeholder='#{field} *']")
      end
      expect(rendered).to have_selector("option", text: "choose")
    end
  end

  context "without consumer_role" do
    before :each do
      sign_in user
      @request.env['HTTP_REFERER'] = ''
      allow(person).to receive(:is_consumer_role_active?).and_return false
      allow(person).to receive(:has_active_employee_role?).and_return true
      assign :person, person
      assign :dependent, dependent
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      render "insured/family_members/dependent_form", dependent: dependent, person: person
    end

    it "should have dependent_list area" do
      expect(rendered).to have_selector("li.dependent_list")
    end

    it "should not have consumer_fields area" do
      expect(rendered).not_to have_selector("div#consumer_fields")
      expect(rendered).not_to match /Are you a US Citizen or US National/
    end

    it "should not have dependent-address area" do
      expect(rendered).not_to have_selector("div#dependent-address")
      expect(rendered).not_to have_selector("div#dependent-home-address-area")
    end

    it "should have required indicator for fields" do
      ["FIRST NAME", "LAST NAME", "DATE OF BIRTH"].each do |field|
        expect(rendered).to have_selector("input[placeholder='#{field} *']")
      end
      expect(rendered).to have_selector("option", text: "choose")
    end

    it "should not display the is_applying_coverage field option" do
      expect(rendered).not_to match /Does this person need coverage?/
    end

    it "should display the affirmative message" do
      expect(rendered).not_to match /Even if you don’t want health coverage for yourself, providing your SSN can be helpful since it can speed up the application process. We use SSNs to check income and other information to see who’s eligible for help with health coverage costs./
    end

    it "should have address info area" do
      expect(rendered).to have_selector('#address_info')
      expect(rendered).to match /Home Address/
    end
  end
end
