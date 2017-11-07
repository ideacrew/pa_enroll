class DocumentsController < ApplicationController
  before_action :updateable?, except: [:show_docs, :download]
  before_action :set_document, only: [:destroy, :update]
  before_action :set_person, only: [:enrollment_docs_state, :fed_hub_request, :enrollment_verification]
  before_action :set_current_person, only: [:update_verification_type]
  respond_to :html, :js

  def download
    bucket = params[:bucket]
    key = params[:key]
    uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket}##{key}"
    send_data Aws::S3Storage.find(uri), get_options(params)
  end

  def authorized_download
    begin
      model = params[:model].camelize
      model_id = params[:model_id]
      relation = params[:relation]
      relation_id = params[:relation_id]
      model_object = Object.const_get(model).find(model_id)
      documents = model_object.send(relation.to_sym)
      if authorized_to_download?(model_object, documents, relation_id)
        uri = documents.find(relation_id).identifier
        send_data Aws::S3Storage.find(uri), get_options(params)
      else
       raise "Sorry! You are not authorized to download this document."
      end
    rescue => e
      redirect_to(:back, :flash => {error: e.message})
    end
  end

  def update_verification_type
    primary_person = @person
    family = primary_person.primary_family
    @person_in_context = Person.find(params["person_id"]) #Can be a dependent or a primary
    family_member = family.family_members.where(:person_id => params["person_id"]).first
    v_type = params[:verification_type]
    update_reason = params[:verification_reason]
    respond_to do |format|
      if ( VlpDocument::VERIFICATION_REASONS + AssistedVerificationDocument::VERIFICATION_REASONS ).uniq.include?(update_reason)
        if FinancialAssistance::AssistedVerification::VERIFICATION_TYPES.include?(params["verification_type"])
          applicant = family.latest_applicable_submitted_application.applicants.where(family_member_id: family_member.id).first
          verification_result = applicant.update_verification_type(v_type, update_reason)
        else
          verification_result = @person_in_context.consumer_role.update_verification_type(v_type, update_reason)
        end

        message = (verification_result.is_a? String) ? verification_result : "Person verification successfully approved."
        format.html { redirect_to :back, :flash => { :success => message} }
      else
        format.html { redirect_to :back, :flash => { :error => "Please provide a verification reason."} }
      end
    end
  end

  def enrollment_verification
    family = @person.primary_family
    if family.try(:active_household).try(:hbx_enrollments).try(:verification_needed).any?
      family.active_household.hbx_enrollments.verification_needed.each do |enrollment|
        enrollment.evaluate_individual_market_eligiblity
      end
      family.save!
      respond_to do |format|
        format.html {
          flash[:success] = "Enrollment group was completely verified."
          redirect_to :back
        }
      end
    else
      respond_to do |format|
        format.html {
          flash[:danger] = "Family does not have any active Enrollment to verify."
          redirect_to :back
        }
      end
    end
  end

  def fed_hub_request
    @person.consumer_role.start_individual_market_eligibility!(TimeKeeper.date_of_record)
    respond_to do |format|
      format.html {
        flash[:success] = "Request was sent to FedHub."
        redirect_to :back
      }
      format.js
    end
  end

  def enrollment_docs_state
    @person.primary_family.active_household.hbx_enrollments.verification_needed.each do |enrollment|
      enrollment.update_attributes(:review_status => "ready")
    end
    flash[:success] = "Your documents were sent for verification."
    redirect_to :back
  end

  def show_docs
    if current_user.has_hbx_staff_role?
      session[:person_id] = params[:person_id]
      set_current_person
      @person.primary_family.active_household.hbx_enrollments.verification_needed.each do |enrollment|
        enrollment.update_attributes(:review_status => "in review")
      end
    end
    redirect_to verification_insured_families_path
  end

  def extend_due_date
    family = Family.find(params[:family_id])
      if family.any_unverified_enrollments?
        if family.enrollments.verification_needed.first.special_verification_period
          new_date = family.enrollments.verification_needed.first.special_verification_period += 30.days
          family.enrollments.verification_needed.first.update_attributes!(:special_verification_period => new_date)
          flash[:success] = "Special verification period was extended for 30 days."
        else
          family.enrollments.verification_needed.first.update_attributes!(:special_verification_period => TimeKeeper.date_of_record + 30.days)
          flash[:success] = "You set special verification period for this Enrollment. Verification due date now is #{family.active_household.hbx_enrollments.verification_needed.first.special_verification_period}"
        end
      else
        flash[:danger] = "Family does not have any active Enrollment to extend verification due date."
      end
    redirect_to :back
  end

  def destroy
    @document.delete
    respond_to do |format|
      format.html { redirect_to verification_insured_families_path }
      format.js
    end

  end

  def update
    if params[:comment]
      @document.update_attributes(:status => params[:status],
                                  :comment => params[:person][:vlp_document][:comment])
    else
      @document.update_attributes(:status => params[:status])
    end
    respond_to do |format|
      format.html {redirect_to verification_insured_families_path, notice: "Document Status Updated"}
      format.js
    end
  end

  private
  def updateable?
    authorize Family, :updateable?
  end

  def get_options(params)
    options = {}
    options[:content_type] = params[:content_type] if params[:content_type]
    options[:filename] = params[:filename] if params[:filename]
    options[:disposition] = params[:disposition] if params[:disposition]
    options
  end

  def authorized_to_download?(owner, documents, document_id)
    return true
    owner.user.has_hbx_staff_role? || documents.find(document_id).present?
  end

  def set_document
    set_person
    @document = @person.consumer_role.vlp_documents.find(params[:id])
  end

  def set_person
    @person = Person.find(params[:person_id])
  end

  def verification_attr
    OpenStruct.new({:determined_at => Time.now,
                    :authority => "hbx"
                   })
  end

end
