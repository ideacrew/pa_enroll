require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "upload_notice_to_employer_account")

describe UploadNoticeToEmployerAccount, dbclean: :after_each do

  let(:given_task_name) { "upload_notice_to_employer_account" }
  subject { UploadNoticeToEmployerAccount.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "UploadNoticeToEmployerAccount" do
    let!(:organization)      { FactoryGirl.create(:organization)}
    let!(:plan_year)         { FactoryGirl.create(:plan_year)}
    let(:bucket_name) { 'notices' }
    let(:file_path) { File.dirname(__FILE__) }
    let(:doc_id) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}{#sample-key" }
    let!(:employer_profile)  { FactoryGirl.create(:employer_profile, organization: organization, plan_years: [plan_year]) }

    before(:each) do
      allow(ENV).to receive(:[]).with('fein').and_return(organization.fein)
      allow(ENV).to receive(:[]).with('notice_name').and_return('Special Enrollment Denial Notice')
      allow(ENV).to receive(:[]).with('file_path').and_return(file_path)
      allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(doc_id)
    end

    it "should upload notice to employer account" do
      expect(employer_profile.documents.size).to eq 0
      subject.migrate
      employer_profile.reload
      expect(employer_profile.documents.size).to eq 1
    end
  end
end
