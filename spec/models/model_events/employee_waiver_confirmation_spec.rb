require 'rails_helper'

RSpec.describe 'ModelEvents::EmployeeWaiverConfirmation', dbclean: :around_each  do

  let(:model_event)  { "employee_waiver_confirmation" }
  let!(:person) { FactoryGirl.create(:person, :with_family) }
  let(:family)  { person.primary_family }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group) }
  let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee) }
  let!(:organization) { FactoryGirl.create(:organization) }
  let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, first_name: person.first_name, last_name: person.last_name) }
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, census_employee_id: census_employee.id, person: person) }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, household: family.active_household, employee_role_id: employee_role.id, benefit_group_id: benefit_group.id, benefit_group_assignment_id: benefit_group_assignment.id ) }
  let!(:model_instance) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, 
    household: family.active_household, 
    employee_role_id: employee_role.id, 
    benefit_group_id: benefit_group.id, 
    aasm_state: "shopping",
    benefit_group_assignment_id: benefit_group_assignment.id) }

  describe "when an employee successfully terminates employer sponsored coverage" do

    let(:subject) { Observers::NoticeObserver.new }

    context "ModelEvent" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:hbx_enrollment_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :employee_waiver_confirmation, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.waive_coverage!
      end
    end

    context "NoticeTrigger" do
      let(:model_event) { ModelEvents::ModelEvent.new(:employee_waiver_confirmation, model_instance, {}) }

      it "should trigger notice event" do

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_waiver_confirmation"
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        subject.hbx_enrollment_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    before do
      model_instance.waive_coverage!
    end

    context "when employee_notice_for_employee_coverage_termination is triggered" do
      let(:data_elements) {
        [
          "employee_profile.notice_date",
          "employee_profile.first_name",
          "employee_profile.last_name",
          "employee_profile.employer_name",
          "employee_profile.enrollment.employee_first_name",
          "employee_profile.enrollment.employee_last_name",
          "employee_profile.enrollment.coverage_kind",
          "employee_profile.enrollment.enrolled_count",
          "employee_profile.enrollment.plan_name",
          "employee_profile.enrollment.waiver_effective_date"

        ]
      }

      let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          "event_object_kind" => "HbxEnrollment",
          "event_object_id" => model_instance.id
      } }
      let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
      let(:merge_model) { subject.construct_notice_object }

      before do
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return notice date" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq model_instance.employer_profile.legal_name
      end

      it "should return employee first_name" do
        expect(merge_model.enrollment.employee_first_name).to eq model_instance.census_employee.first_name
      end

      it "should return employee last_name" do
        expect(merge_model.enrollment.employee_last_name).to eq model_instance.census_employee.last_name
      end

      it "should return enrollment coverage_kind" do
        expect(merge_model.enrollment.coverage_kind).to eq model_instance.coverage_kind
      end

      it "should return enrollment covered dependents" do
        expect(merge_model.enrollment.enrolled_count).to eq model_instance.humanized_dependent_summary.to_s
      end

      it "should return enrollment" do
        expect(merge_model.enrollment.waiver_effective_date).to eq model_instance.created_at.strftime('%m/%d/%Y')
      end

      it "should return enrollment coverage_kind" do
        expect(merge_model.enrollment.plan_name).to eq model_instance.plan.name
      end
    end
  end
end
